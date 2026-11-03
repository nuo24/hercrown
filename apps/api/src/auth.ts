// Better Auth inside the Worker, storing users in D1 (ai-app-playbook chapter 04).
// Anonymous first; Sign in with Apple links the guest to a real account. Native clients use bearer tokens.
import { betterAuth } from "better-auth";
import { anonymous, bearer } from "better-auth/plugins";
import { env } from "cloudflare:workers";
import { linkPerson } from "./events";
import { deleteUserData, moveUserData } from "./users";

// Created on first use, not at module load: Better Auth validates the schema when it starts and caches
// the result, so starting before migrations are applied would leave auth failing for the isolate's lifetime.
let instance: ReturnType<typeof createAuth> | undefined;
export const getAuth = () => (instance ??= createAuth());

const createAuth = () => betterAuth({
  database: env.DB, // the D1 binding, used directly
  secret: env.BETTER_AUTH_SECRET,
  baseURL: env.BETTER_AUTH_URL,
  trustedOrigins: ["https://appleid.apple.com"],

  socialProviders: env.APPLE_CLIENT_ID
    ? {
        apple: {
          clientId: env.APPLE_CLIENT_ID,
          clientSecret: env.APPLE_CLIENT_SECRET,
          // Required for native iOS idToken sign-in (the token's `aud` is the bundle id).
          appBundleIdentifier: env.APPLE_APP_BUNDLE_IDENTIFIER,
        },
      }
    : {},

  // App Store 5.1.1(v): account deletion must be available in the app.
  user: { deleteUser: { enabled: true } },

  databaseHooks: {
    user: {
      delete: {
        // Runs on every deletion path: delete-user, delete-anonymous-user and the
        // guest cleanup after linking (by then moveUserData has emptied the guest's rows).
        before: async (user) => {
          await deleteUserData(env, user.id);
        },
      },
    },
  },

  plugins: [
    anonymous({
      emailDomainName: "guest.biblescroll.invalid",
      generateName: () => "Guest",
      // Runs when a guest signs in with Apple; Better Auth deletes the guest user afterwards.
      onLinkAccount: async ({ anonymousUser, newUser }) => {
        await moveUserData(env, anonymousUser.user.id, newUser.user.id);
        const accountIsNew = new Date(newUser.user.createdAt) >= new Date(anonymousUser.user.createdAt);
        await linkPerson(env, anonymousUser.user.id, newUser.user.id, accountIsNew);
      },
    }),
    // Native clients read the `set-auth-token` header and send `Authorization: Bearer <token>`.
    bearer(),
  ],
});
