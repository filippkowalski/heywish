import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Terms of Service - Jinnie',
  description: 'Terms of Service for Jinnie wishlist platform',
};

export default function TermsOfService() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto bg-white rounded-lg shadow-sm p-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Terms of Service</h1>
        <p className="text-sm text-gray-500 mb-8">Last updated: October 22, 2025</p>

        <div className="prose prose-gray max-w-none">
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">1. Acceptance of Terms</h2>
            <p className="text-gray-700 mb-4">
              Welcome to Jinnie! By accessing or using our wishlist platform ("Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use our Service.
            </p>
            <p className="text-gray-700">
              These Terms apply to all visitors, users, and others who access or use the Service, whether through our mobile application or website.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">2. Description of Service</h2>
            <p className="text-gray-700 mb-4">
              Jinnie is a social wishlist platform that allows users to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Create and manage personal wishlists</li>
              <li>Share wishlists with friends and family</li>
              <li>Reserve gifts from friends' wishlists</li>
              <li>Discover new products through our platform</li>
              <li>Connect with other users through social features</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">3. User Accounts</h2>
            <h3 className="text-xl font-semibold text-gray-900 mb-3">3.1 Account Creation</h3>
            <p className="text-gray-700 mb-4">
              To use certain features of Jinnie, you must create an account. You may register using:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Email and password</li>
              <li>Google authentication</li>
              <li>Apple Sign-In</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">3.2 Account Responsibility</h3>
            <p className="text-gray-700 mb-4">
              You are responsible for:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Maintaining the confidentiality of your account credentials</li>
              <li>All activities that occur under your account</li>
              <li>Notifying us immediately of any unauthorized use</li>
              <li>Ensuring your account information is accurate and up-to-date</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">4. User Content</h2>
            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.1 Your Content</h3>
            <p className="text-gray-700 mb-4">
              Users may post, upload, or share content including:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Wishlist items and descriptions</li>
              <li>Profile information and photos</li>
              <li>Comments and interactions with other users</li>
            </ul>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.2 Content License</h3>
            <p className="text-gray-700 mb-4">
              By posting content on Jinnie, you grant us a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content solely for the purpose of operating and improving our Service.
            </p>

            <h3 className="text-xl font-semibold text-gray-900 mb-3">4.3 Content Guidelines</h3>
            <p className="text-gray-700 mb-4">
              You agree not to post content that:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Violates any laws or regulations</li>
              <li>Infringes on intellectual property rights</li>
              <li>Contains harmful, offensive, or inappropriate material</li>
              <li>Impersonates another person or entity</li>
              <li>Contains spam or unsolicited promotions</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">5. Affiliate Links and Disclosures</h2>
            <p className="text-gray-700 mb-4">
              Jinnie may include affiliate links to third-party products and services. When you click on these links and make a purchase, we may earn a commission at no additional cost to you.
            </p>
            <p className="text-gray-700">
              We clearly mark affiliate links and maintain transparency about our affiliate relationships. Our affiliate partnerships do not influence the quality or integrity of our Service.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">6. Privacy</h2>
            <p className="text-gray-700">
              Your privacy is important to us. Please review our{' '}
              <a href="/privacy" className="text-blue-600 hover:text-blue-800 underline">
                Privacy Policy
              </a>
              {' '}to understand how we collect, use, and protect your personal information.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">7. Prohibited Conduct</h2>
            <p className="text-gray-700 mb-4">
              You agree not to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Use the Service for any illegal purpose</li>
              <li>Interfere with or disrupt the Service or servers</li>
              <li>Attempt to gain unauthorized access to any part of the Service</li>
              <li>Harass, abuse, or harm other users</li>
              <li>Use automated systems (bots, scrapers) without permission</li>
              <li>Collect or harvest user data without consent</li>
              <li>Create multiple accounts to abuse our features</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">8. Intellectual Property</h2>
            <p className="text-gray-700 mb-4">
              The Service and its original content (excluding user-generated content), features, and functionality are owned by Jinnie and are protected by international copyright, trademark, and other intellectual property laws.
            </p>
            <p className="text-gray-700">
              Our trademarks, logos, and service marks may not be used without our prior written permission.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">9. Third-Party Links and Services</h2>
            <p className="text-gray-700 mb-4">
              Our Service may contain links to third-party websites, products, or services that are not owned or controlled by Jinnie.
            </p>
            <p className="text-gray-700">
              We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services. You acknowledge and agree that we shall not be liable for any damage or loss caused by your use of third-party content.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">10. Disclaimers</h2>
            <p className="text-gray-700 mb-4">
              THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Warranties of merchantability or fitness for a particular purpose</li>
              <li>Non-infringement or security</li>
              <li>Accuracy, reliability, or completeness of content</li>
              <li>Uninterrupted or error-free operation</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">11. Limitation of Liability</h2>
            <p className="text-gray-700">
              TO THE MAXIMUM EXTENT PERMITTED BY LAW, JINNIE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY, OR ANY LOSS OF DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES RESULTING FROM:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mt-4">
              <li>Your use or inability to use the Service</li>
              <li>Unauthorized access to or alteration of your content</li>
              <li>Third-party conduct or content on the Service</li>
              <li>Any other matter related to the Service</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">12. Termination</h2>
            <p className="text-gray-700 mb-4">
              We reserve the right to terminate or suspend your account and access to the Service at our sole discretion, without notice, for conduct that we believe:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Violates these Terms</li>
              <li>Is harmful to other users, us, or third parties</li>
              <li>Violates applicable law</li>
            </ul>
            <p className="text-gray-700">
              Upon termination, your right to use the Service will immediately cease. You may also delete your account at any time through the app settings.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">13. Changes to Terms</h2>
            <p className="text-gray-700">
              We reserve the right to modify these Terms at any time. If we make material changes, we will notify you through the Service or via email. Your continued use of the Service after such modifications constitutes your acceptance of the updated Terms.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">14. Governing Law</h2>
            <p className="text-gray-700">
              These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which Jinnie operates, without regard to its conflict of law provisions.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">15. Contact Us</h2>
            <p className="text-gray-700 mb-4">
              If you have any questions about these Terms, please contact us at:
            </p>
            <p className="text-gray-700">
              Email:{' '}
              <a href="mailto:support@jinnie.co" className="text-blue-600 hover:text-blue-800 underline">
                support@jinnie.co
              </a>
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
