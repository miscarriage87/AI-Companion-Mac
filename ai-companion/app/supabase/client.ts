// Using a more compatible approach without direct imports
// This avoids the need for the @supabase/supabase-js package

type SupabaseClient = {
  auth: {
    signInWithPassword: (credentials: { email: string; password: string }) => Promise<any>;
    signUp: (credentials: { email: string; password: string }) => Promise<any>;
    signOut: () => Promise<any>;
    getSession: () => Promise<{ data: { session: any } }>;
    onAuthStateChange: (callback: (event: string, session: any) => void) => { data: { subscription: { unsubscribe: () => void } } };
  };
};

// Mock Supabase client for development
export const supabase: SupabaseClient = {
  auth: {
    signInWithPassword: async ({ email, password }) => {
      console.log("Mock sign in with:", email, password);
      // For development, simulate successful login
      return { error: null };
    },
    signUp: async ({ email, password }) => {
      console.log("Mock sign up with:", email, password);
      // For development, simulate successful signup
      return { error: null };
    },
    signOut: async () => {
      console.log("Mock sign out");
      return { error: null };
    },
    getSession: async () => {
      // For development, simulate a session
      return {
        data: {
          session: {
            user: {
              id: "mock-user-id",
              email: "user@example.com"
            }
          }
        }
      };
    },
    onAuthStateChange: (callback) => {
      // For development, simulate auth state change
      return {
        data: {
          subscription: {
            unsubscribe: () => {}
          }
        }
      };
    }
  }
};

export const createClient = () => supabase;