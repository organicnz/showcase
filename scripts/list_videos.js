import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://smyfjmdjzfwdehynwfep.supabase.co'
const supabaseKey = 'sb_publishable_36vglboOi9AkwTwCw_BqMg_uWQE8NV_'

const supabase = createClient(supabaseUrl, supabaseKey)

async function listFiles() {
  const { data, error } = await supabase.storage.from('videos').list()
  if (error) {
    console.error('Error:', error)
  } else {
    data.forEach(f => console.log(f.name, f.metadata.size, f.metadata.eTag))
  }
}

listFiles()
