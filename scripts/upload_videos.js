import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const supabaseUrl = 'https://smyfjmdjzfwdehynwfep.supabase.co';
const supabaseKey = 'sb_publishable_36vglboOi9AkwTwCw_BqMg_uWQE8NV_';

const supabase = createClient(supabaseUrl, supabaseKey);

async function uploadFile(filename) {
  const filePath = path.join(process.cwd(), 'assets', 'videos', filename);
  const fileBuffer = fs.readFileSync(filePath);
  
  const { data, error } = await supabase.storage
    .from('videos')
    .upload(filename, fileBuffer, {
      contentType: 'video/mp4',
      upsert: true
    });
    
  if (error) {
    console.error(`Error uploading ${filename}:`, error.message);
  } else {
    console.log(`Successfully uploaded ${filename}`);
  }
}

async function main() {
  const files = [
    'v_family_fix.mp4',
    'v_wellness_fix.mp4',
    'v_guests_fix.mp4',
    'v_investor_fix.mp4',
    'v_architecture_fix.mp4'
  ];
  
  for (const file of files) {
    await uploadFile(file);
  }
}

main();
