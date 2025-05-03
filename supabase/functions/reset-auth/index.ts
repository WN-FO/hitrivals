// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

console.log("Hello from Functions!")

Deno.serve(async (req) => {
  try {
    // Create a Supabase client with the Admin key
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)
    
    // Instead of using RPC, let's use direct SQL to modify auth settings
    const { data, error } = await supabase
      .from('auth_config')
      .update({
        redirect_urls: ['com.hitrivals.app://login-callback'],
        email_confirmations: false,
        double_confirm_email_changes: false,
        enable_signup: true
      })
      .eq('id', 1)
    
    if (error) throw error
    
    return new Response(
      JSON.stringify({ 
        message: "Auth settings updated successfully",
        data
      }),
      { 
        headers: { "Content-Type": "application/json" },
        status: 200
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { "Content-Type": "application/json" },
        status: 400
      },
    )
  }
})

/* To invoke:
 * curl -i --location --request POST 'http://localhost:54321/functions/v1/reset-auth' \
 *   --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
 *   --header 'Content-Type: application/json' \
 *   --data '{}'
 */
