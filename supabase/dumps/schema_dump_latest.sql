-- ==============================================================================
-- SHOWCASE МЕЩЕРСКИЙ ПАРК — СХЕМА БАЗЫ ДАННЫХ POSTGRESQL (SUPABASE)
-- Проект: Showcase (Плеер презентаций для офиса продаж)
-- Заказчик: ООО «СПК-М»
-- Инстанс: smyfjmdjzfwdehynwfep (PostgreSQL 17.6)
-- Дата выгрузки: 2026-10-13
-- Назначение: Официальный DDL-дамп для Акта сдачи-приемки (Этап № 1)
-- ==============================================================================

-- 1. РАСШИРЕНИЯ (EXTENSIONS)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- ==============================================================================
-- 2. ТАБЛИЦЫ (TABLES)
-- ==============================================================================

-- 2.1 Сценарии образа жизни (Scenarios)
CREATE TABLE IF NOT EXISTS public.scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon_name TEXT,
    image_path TEXT,
    ambient_audio_path TEXT,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.scenarios IS 'Жизненные сценарии Мещерского парка (карточки на планшете)';
COMMENT ON COLUMN public.scenarios.slug IS 'Уникальный текстовый идентификатор (family, wellness, guests, investor, architecture)';
COMMENT ON COLUMN public.scenarios.order_index IS 'Порядковый номер для сортировки отображения';

-- 2.2 Видеоматериалы (Videos)
CREATE TABLE IF NOT EXISTS public.videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID NOT NULL REFERENCES public.scenarios(id) ON DELETE CASCADE,
    title TEXT,
    subtitle TEXT,
    storage_path TEXT NOT NULL,
    thumbnail_path TEXT,
    duration_sec INTEGER,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    highlights JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.videos IS 'Каталог видеороликов, привязанных к сценариям';
COMMENT ON COLUMN public.videos.storage_path IS 'Относительный путь к файлу в Supabase Storage (бакет videos)';
COMMENT ON COLUMN public.videos.highlights IS 'Массив ключевых особенностей для оверлея на экране';

-- 2.3 Фотогалерея / Архитектурные рендеры (Photos)
CREATE TABLE IF NOT EXISTS public.photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID REFERENCES public.scenarios(id) ON DELETE CASCADE,
    title TEXT,
    subtitle TEXT,
    storage_path TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.photos IS 'Галерея статичных фото и архитектурных рендеров';

-- 2.4 Состояния движка Antigravity Workflow Engine (AWE)
CREATE TABLE IF NOT EXISTS public.workflow_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_name TEXT NOT NULL,
    current_step_index INTEGER NOT NULL DEFAULT 0,
    completed_steps TEXT[] NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'pending',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.workflow_states IS 'Персистентные стейты сценариев воспроизведения и переходов AWE';

-- 2.5 Пользовательские настройки терминалов (User Settings)
CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id UUID PRIMARY KEY,
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.user_settings IS 'Локальные настройки планшетов менеджеров офиса продаж';

-- ==============================================================================
-- 3. ИНДЕКСЫ (INDEXES & QUERY OPTIMIZATIONS)
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_scenarios_active_order 
    ON public.scenarios(active, order_index);

CREATE INDEX IF NOT EXISTS idx_videos_scenario_active_order 
    ON public.videos(scenario_id, active, order_index);

CREATE INDEX IF NOT EXISTS idx_videos_active 
    ON public.videos(active);

CREATE INDEX IF NOT EXISTS idx_photos_scenario_active_order
    ON public.photos(scenario_id, active, order_index);

CREATE INDEX IF NOT EXISTS idx_photos_active
    ON public.photos(active);

CREATE INDEX IF NOT EXISTS idx_workflow_states_name_updated
    ON public.workflow_states(workflow_name, updated_at DESC);

-- ==============================================================================
-- 4. ТРИГГЕРЫ И ФУНКЦИИ ВАЛИДАЦИИ (STORAGE VALIDATION)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.validate_video_storage_path()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.storage_path IS NOT NULL AND NEW.storage_path NOT LIKE 'http%' THEN
    IF NEW.storage_path !~ '^(family|wellness|guests|investor|architecture)/' THEN
      RAISE EXCEPTION 'Некорректный storage_path: должен начинаться с папки сценария (family/, wellness/, guests/, investor/, architecture/)';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS validate_video_storage_path_trigger ON public.videos;
CREATE TRIGGER validate_video_storage_path_trigger
  BEFORE INSERT OR UPDATE ON public.videos
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_video_storage_path();

-- ==============================================================================
-- 5. ПРЕДСТАВЛЕНИЯ (VIEWS)
-- ==============================================================================

CREATE OR REPLACE VIEW public.videos_with_cdn_urls 
WITH (security_invoker = true) AS
SELECT 
  v.id,
  v.scenario_id,
  s.slug AS scenario_slug,
  v.title,
  v.storage_path,
  CASE 
    WHEN v.storage_path LIKE 'http%' THEN v.storage_path
    ELSE 'https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/' || v.storage_path
  END AS cdn_url,
  v.duration_sec,
  v.order_index,
  v.active,
  v.highlights,
  v.created_at
FROM public.videos v
JOIN public.scenarios s ON v.scenario_id = s.id
ORDER BY s.order_index, v.order_index;

COMMENT ON VIEW public.videos_with_cdn_urls IS 'Представление с готовыми CDN ссылками для стриминга на внешние дисплеи';

-- ==============================================================================
-- 6. БЕЗОПАСНОСТЬ И ROW LEVEL SECURITY (RLS)
-- ==============================================================================

ALTER TABLE public.scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- 6.1 Публичное чтение активного контента (Планшеты в офисе продаж)
DROP POLICY IF EXISTS "Allow public read access for active scenarios" ON public.scenarios;
CREATE POLICY "Allow public read access for active scenarios"
    ON public.scenarios FOR SELECT
    USING (active = true);

DROP POLICY IF EXISTS "Allow public read access for active videos" ON public.videos;
CREATE POLICY "Allow public read access for active videos"
    ON public.videos FOR SELECT
    USING (active = true);

DROP POLICY IF EXISTS "Allow public read access for photos" ON public.photos;
CREATE POLICY "Allow public read access for photos"
    ON public.photos FOR SELECT
    USING (active = true);

-- 6.2 Управление AWE стейтами
DROP POLICY IF EXISTS "Enable select for anon users" ON public.workflow_states;
CREATE POLICY "Enable select for anon users" 
    ON public.workflow_states FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.workflow_states;
CREATE POLICY "Enable all for authenticated users" 
    ON public.workflow_states FOR ALL 
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 6.3 Пользовательские настройки планшета
DROP POLICY IF EXISTS "Users can read own settings" ON public.user_settings;
CREATE POLICY "Users can read own settings"
    ON public.user_settings FOR SELECT
    TO authenticated
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;
CREATE POLICY "Users can update own settings"
    ON public.user_settings FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- ==============================================================================
-- 7. ШИФРОВАНИЕ И ХРАНИЛИЩЕ СЕКРЕТОВ (SUPABASE VAULT)
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS vault WITH SCHEMA vault;

CREATE OR REPLACE FUNCTION public.get_secret(secret_name text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = vault, public
AS $$
DECLARE
  secret_val text;
BEGIN
  SELECT decrypted_secret INTO secret_val
  FROM vault.decrypted_secrets
  WHERE name = secret_name
  LIMIT 1;
  RETURN secret_val;
END;
$$;

COMMENT ON FUNCTION public.get_secret(text) IS 
  'Безопасное получение расшифрованного секрета из Supabase Vault. Доступ разрешен только для service_role.';

REVOKE ALL ON FUNCTION public.get_secret(text) FROM public;
REVOKE ALL ON FUNCTION public.get_secret(text) FROM anon;
REVOKE ALL ON FUNCTION public.get_secret(text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.get_secret(text) TO service_role;

-- ==============================================================================
-- КОНЕЦ ДАМПА СХЕМЫ
-- ==============================================================================
