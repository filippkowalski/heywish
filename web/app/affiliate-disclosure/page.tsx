import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Affiliate Disclosure - Jinnie',
  description: 'Affiliate Disclosure for Jinnie wishlist platform',
};

export default function AffiliateDisclosure() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto bg-white rounded-lg shadow-sm p-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Affiliate Disclosure</h1>
        <p className="text-sm text-gray-500 mb-8">Last updated: January 4, 2025</p>

        <div className="prose prose-gray max-w-none">
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">1. Introduction</h2>
            <p className="text-gray-700 mb-4">
              Jinnie (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;) participates in affiliate marketing programs, which means we may earn commissions when you click on certain links in our Service and make purchases from participating merchants.
            </p>
            <p className="text-gray-700">
              This disclosure is intended to comply with the Federal Trade Commission&apos;s requirements regarding affiliate marketing and endorsements, and to be transparent with you about how we monetize our wishlist platform.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">2. What Are Affiliate Links?</h2>
            <p className="text-gray-700 mb-4">
              An affiliate link is a special URL that contains a unique tracking code. When you click on an affiliate link and make a purchase from a merchant, we may earn a commission from that merchant at no additional cost to you.
            </p>
            <p className="text-gray-700">
              The commission we receive does not affect the price you pay. The price is the same whether you use our affiliate link or go directly to the merchant&apos;s website.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">3. How We Use Affiliate Links</h2>
            <p className="text-gray-700 mb-4">
              When you add items to your wishlists from supported merchants, or when you view items in wishlists shared by others, some product links may be affiliate links. This means:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>When you click on a product link and visit a merchant&apos;s website, a tracking cookie may be placed on your device</li>
              <li>If you make a purchase from that merchant within the cookie&apos;s valid period (typically 24 hours to 30 days, depending on the merchant), we may earn a commission</li>
              <li>The commission is paid by the merchant, not by you</li>
              <li>The price you pay is the same regardless of whether you use our affiliate link</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">4. Affiliate Networks We Work With</h2>
            <p className="text-gray-700 mb-4">
              We participate in affiliate programs through various affiliate networks and merchants, including but not limited to:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>Amazon Associates Program</li>
              <li>Awin Affiliate Network</li>
              <li>Impact Partnership Network</li>
              <li>ShareASale</li>
              <li>Rakuten Advertising</li>
              <li>Individual merchant affiliate programs</li>
            </ul>
            <p className="text-gray-700">
              This list may change over time as we add or remove affiliate partnerships. We will update this disclosure accordingly.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">5. Our Commitment to Transparency</h2>
            <p className="text-gray-700 mb-4">
              We are committed to being transparent about our use of affiliate links:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li><strong>No Impact on Recommendations:</strong> Our affiliate relationships do not influence which products you choose to add to your wishlists. You have complete control over your wishlist content.</li>
              <li><strong>No Additional Cost:</strong> You will never pay more when using our affiliate links. The price is always the same as going directly to the merchant.</li>
              <li><strong>User Control:</strong> You are free to search for products directly on merchant websites instead of using links in Jinnie.</li>
              <li><strong>Clear Labeling:</strong> We strive to clearly indicate when links may be affiliate links where appropriate.</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">6. How This Supports Jinnie</h2>
            <p className="text-gray-700 mb-4">
              Affiliate commissions help us:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2">
              <li>Keep Jinnie free for all users</li>
              <li>Maintain and improve our platform</li>
              <li>Develop new features and functionality</li>
              <li>Provide customer support</li>
              <li>Cover infrastructure and operational costs</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">7. Your Privacy</h2>
            <p className="text-gray-700 mb-4">
              When you click on affiliate links:
            </p>
            <ul className="list-disc pl-6 text-gray-700 space-y-2 mb-4">
              <li>The merchant may place tracking cookies on your device to track your purchase</li>
              <li>The merchant has its own privacy policy governing how they handle your data</li>
              <li>We may receive aggregated data about clicks and conversions, but we do not receive your personal purchase information or payment details</li>
              <li>You can manage cookies through your browser settings, though this may affect the functionality of some merchant websites</li>
            </ul>
            <p className="text-gray-700">
              For more information about how we handle your data, please see our <a href="/privacy" className="text-blue-600 hover:text-blue-800 underline">Privacy Policy</a>.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">8. Third-Party Merchant Policies</h2>
            <p className="text-gray-700">
              Each merchant has its own return policies, shipping policies, customer service, and terms of service. Jinnie is not responsible for the products, services, or policies of third-party merchants. Any purchases you make are between you and the merchant. If you have questions or issues with a purchase, please contact the merchant directly.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">9. Special Notice for Amazon Associates</h2>
            <p className="text-gray-700">
              Jinnie is a participant in the Amazon Services LLC Associates Program, an affiliate advertising program designed to provide a means for sites to earn advertising fees by advertising and linking to Amazon.com and affiliated sites. As an Amazon Associate, we earn from qualifying purchases.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">10. Changes to This Disclosure</h2>
            <p className="text-gray-700">
              We may update this Affiliate Disclosure from time to time to reflect changes in our affiliate partnerships or practices. We will notify you of any material changes by updating the &quot;Last updated&quot; date at the top of this page. We encourage you to review this disclosure periodically.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">11. Contact Us</h2>
            <p className="text-gray-700 mb-4">
              If you have questions about our use of affiliate links or this disclosure, please contact us:
            </p>
            <p className="text-gray-700">
              Email:{' '}
              <a href="mailto:support@jinnie.co" className="text-blue-600 hover:text-blue-800 underline">
                support@jinnie.co
              </a>
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">12. Legal Disclaimer</h2>
            <p className="text-gray-700">
              The information provided on Jinnie is for general informational purposes only. We make no representations or warranties of any kind about the completeness, accuracy, reliability, suitability, or availability of products or merchants linked through our Service. Your use of any information or materials on merchant websites is entirely at your own risk.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
