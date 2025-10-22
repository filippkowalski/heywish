import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Privacy Policy - Jinnie',
  description: 'Privacy Policy for Jinnie wishlist platform',
};

export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto bg-white rounded-lg shadow-sm p-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Privacy Policy</h1>
        <p className="text-sm text-gray-500 mb-8">Last updated: October 22, 2025</p>

        <div className="prose prose-gray max-w-none">
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">1. Introduction</h2>
            <p className="text-gray-700 mb-4">
              Welcome to Jinnie ("we," "our," or "us"). We are committed to protecting your privacy and ensuring you have a positive experience when using our wishlist platform.
            </p>
            <p className="text-gray-700">
              This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and website (collectively, the "Service"). Please read this privacy policy carefully.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">2. Information We Collect</h2>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">2.1 Information You Provide</h3>
            <p className="text-gray-700 mb-4">
              We collect information that you voluntarily provide when you:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li><strong>Create an account:</strong> Email address, name, username, password (encrypted)</li>
              <li><strong>Complete your profile:</strong> Profile photo, bio, birthday, gender, shopping interests</li>
              <li><strong>Create wishlists:</strong> Wishlist names, wish items, descriptions, prices, images, product URLs</li>
              <li><strong>Interact with others:</strong> Friend requests, messages, comments</li>
              <li><strong>Contact us:</strong> Name, email, message content when you reach out to support</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">2.2 Authentication Information</h3>
            <p className="text-gray-700 mb-4">
              When you sign in using third-party services, we collect:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li><strong>Google Sign-In:</strong> Name, email address, profile picture</li>
              <li><strong>Apple Sign-In:</strong> Name (optional), email address (or private relay email)</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">2.3 Automatically Collected Information</h3>
            <p className="text-gray-700 mb-4">
              When you use our Service, we automatically collect:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li><strong>Device Information:</strong> Device type, operating system, unique device identifiers</li>
              <li><strong>Usage Data:</strong> Features used, pages viewed, time spent, interaction patterns</li>
              <li><strong>Log Data:</strong> IP address, browser type, access times, error logs</li>
              <li><strong>Analytics:</strong> App performance, crash reports, feature usage statistics</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">3. How We Use Your Information</h2>
            <p className="text-gray-700 mb-4">
              We use the collected information for:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li><strong>Providing the Service:</strong> Creating and managing your account, wishlists, and social features</li>
              <li><strong>Personalization:</strong> Customizing your experience based on your preferences and interests</li>
              <li><strong>Communication:</strong> Sending notifications, updates, and responding to your inquiries</li>
              <li><strong>Improvement:</strong> Analyzing usage patterns to enhance our Service and develop new features</li>
              <li><strong>Security:</strong> Detecting, preventing, and addressing fraud, security issues, and technical problems</li>
              <li><strong>Compliance:</strong> Fulfilling legal obligations and enforcing our Terms of Service</li>
              <li><strong>Marketing:</strong> Sending promotional content (you can opt-out at any time)</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">4. Information Sharing and Disclosure</h2>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.1 With Other Users</h3>
            <p className="text-gray-700 mb-4">
              Based on your privacy settings:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li><strong>Public Profiles:</strong> Your profile, wishlists, and activity may be visible to all users and accessible via public URLs</li>
              <li><strong>Private Profiles:</strong> Your detailed information is only visible to friends, though your username and basic profile may still be searchable</li>
              <li><strong>Friends:</strong> Friends can view your wishlists, activity, and profile details based on your settings</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.2 With Service Providers</h3>
            <p className="text-gray-700 mb-4">
              We share information with trusted third parties who help us operate our Service:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li><strong>Firebase (Google):</strong> Authentication and user management</li>
              <li><strong>Cloudflare:</strong> Content delivery, storage (R2), and infrastructure</li>
              <li><strong>Database Hosting:</strong> Secure storage of user data</li>
              <li><strong>Analytics Providers:</strong> Usage analytics and crash reporting</li>
              <li><strong>Email Services:</strong> Transactional and promotional emails</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.3 Affiliate Partners</h3>
            <p className="text-gray-700 mb-4">
              When you click on affiliate links to third-party products:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>The merchant may collect information about your visit and purchase</li>
              <li>We may receive aggregated data about clicks and purchases (no personal information)</li>
              <li>Each merchant has their own privacy policy governing their data practices</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.4 Legal Requirements</h3>
            <p className="text-gray-700 mb-4">
              We may disclose your information if required by law or if we believe it's necessary to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Comply with legal processes, government requests, or court orders</li>
              <li>Protect our rights, property, or safety, or that of our users</li>
              <li>Prevent or investigate potential fraud or security issues</li>
              <li>Enforce our Terms of Service</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">5. Data Storage and Security</h2>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">5.1 Security Measures</h3>
            <p className="text-gray-700 mb-4">
              We implement industry-standard security measures including:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Encryption of data in transit and at rest</li>
              <li>Secure password hashing (never stored in plain text)</li>
              <li>Regular security audits and updates</li>
              <li>Access controls and authentication</li>
              <li>Monitoring for suspicious activity</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">5.2 Data Retention</h3>
            <p className="text-gray-700">
              We retain your information for as long as your account is active or as needed to provide you services. You can request deletion of your account and associated data at any time through the app settings.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">6. Your Rights and Choices</h2>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">6.1 Access and Update</h3>
            <p className="text-gray-700 mb-4">
              You can:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Access and update your profile information at any time</li>
              <li>Edit or delete your wishlists and wish items</li>
              <li>Manage your friend connections</li>
              <li>Update your privacy settings</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">6.2 Privacy Settings</h3>
            <p className="text-gray-700 mb-4">
              You control:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Profile visibility (public or private)</li>
              <li>Who can see your wishlists</li>
              <li>Notification preferences</li>
              <li>Email communication preferences</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">6.3 Account Deletion</h3>
            <p className="text-gray-700 mb-4">
              You can delete your account at any time, which will:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Permanently remove your profile and wishlists</li>
              <li>Delete your personal information from our systems</li>
              <li>Remove your friendships and social connections</li>
              <li>Cancel any pending reservations</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">7. Children's Privacy</h2>
            <p className="text-gray-700">
              Our Service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us so we can delete it.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">8. International Data Transfers</h2>
            <p className="text-gray-700">
              Your information may be transferred to and processed in countries other than your own. These countries may have different data protection laws. By using our Service, you consent to the transfer of your information to these countries. We take appropriate measures to ensure your data is treated securely and in accordance with this Privacy Policy.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">9. Cookies and Tracking Technologies</h2>
            <p className="text-gray-700 mb-4">
              We use cookies and similar tracking technologies to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Maintain your session and keep you logged in</li>
              <li>Remember your preferences</li>
              <li>Analyze how you use our Service</li>
              <li>Track affiliate link clicks</li>
            </ul>
            <p className="text-gray-700">
              You can control cookies through your browser settings, but some features may not work properly if you disable cookies.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">10. Third-Party Links</h2>
            <p className="text-gray-700">
              Our Service contains links to third-party websites and services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies before providing them with your information.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">11. Changes to This Privacy Policy</h2>
            <p className="text-gray-700">
              We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new Privacy Policy on this page and updating the "Last updated" date. We may also send you an email or in-app notification about significant changes.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">12. Contact Us</h2>
            <p className="text-gray-700 mb-4">
              If you have questions about this Privacy Policy or how we handle your data, please contact us:
            </p>
            <p className="text-gray-700">
              Email:{' '}
              <a href="mailto:privacy@jinnie.co" className="text-blue-600 hover:text-blue-800 underline">
                privacy@jinnie.co
              </a>
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">13. Your California Privacy Rights</h2>
            <p className="text-gray-700 mb-4">
              If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA):
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Right to know what personal information we collect, use, and disclose</li>
              <li>Right to request deletion of your personal information</li>
              <li>Right to opt-out of the sale of personal information (we do not sell your data)</li>
              <li>Right to non-discrimination for exercising your privacy rights</li>
            </ul>
          </section>
        </div>
      </div>
    </div>
  );
}
