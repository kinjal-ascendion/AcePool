class ApiKeys {
  ApiKeys._();

  // Replace with your Google Cloud API key.
  // Enable: Places API (New) at console.cloud.google.com
  static const String googlePlaces = 'AIzaSyDWyEtGb4cwt521OD0iTQtu1attYEAvEuA';

  // EmailJS credentials — https://www.emailjs.com
  // 1. Sign up at emailjs.com (free: 200 emails/month)
  // 2. Add an email service (Gmail/Outlook) under Email Services
  // 3. Create a template with variables: {{otp}} and {{to_email}}
  // 4. Paste Service ID, Template ID, and Public Key below
  static const String emailJsServiceId = 'service_vb15p0f';
  static const String emailJsTemplateId = 'template_swisqbp';
  static const String emailJsPublicKey = 'vRIlgFkMhRAFo3qLw';
  static const String emailJsPrivateKey = 'VAH8_1cp8ZNTB7M5_ck7w';

  // Microsoft/Azure AD (Entra ID) SSO — https://portal.azure.com
  // 1. Register an app in Ascendion's Azure AD tenant (App registrations > New registration)
  // 2. Supported account types: single-tenant (this org only)
  // 3. Add Firebase's Microsoft OAuth redirect URI shown in Firebase Console
  //    (Authentication > Sign-in method > Microsoft) to the app's Redirect URIs
  // 4. Copy the Directory (tenant) ID below, and paste the Application (client) ID
  //    + a generated Client Secret into the Firebase Console Microsoft provider config
  static const String microsoftTenantId =
      'd7758e8f-1df3-489f-86b5-a2254f55f9cc';
}
