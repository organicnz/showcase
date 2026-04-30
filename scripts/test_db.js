import { createClient } from '@supabase/supabase-js'
import fs from 'fs'

const supabaseUrl = process.env.SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseKey = process.env.SUPABASE_ANON_KEY || ''
// Let's get the keys from the SupabaseManager.swift
