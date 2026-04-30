import { createClient } from '@supabase/supabase-js'
import fs from 'fs'

const supabaseUrl = 'https://smyfjmdjzfwdehynwfep.supabase.co'
const supabaseKey = 'sb_publishable_36vglboOi9AkwTwCw_BqMg_uWQE8NV_'

const supabase = createClient(supabaseUrl, supabaseKey)

async function upload() {
  try {
    const fileData = fs.readFileSync('assets/photos/family_white.jpg')
    const { data, error } = await supabase
      .storage
      .from('photos')
      .upload('family_white.jpg', fileData, {
        contentType: 'image/jpeg',
        upsert: true
      })
    
    if (error) {
      console.error('Error uploading:', error)
      return
    }
    
    console.log('Upload successful:', data)
  } catch (err) {
    console.error('Exception:', err)
  }
}

upload()
