import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  static const String _businessPhoneDisplay = '03008409358';
  static const String _businessPhoneInternational = '923008409358';
  static const String _facebookPageUrl = 'https://facebook.com/asaldairy';
  static const String _instagramUsername = 'asaldairymilk';
  static const String _websiteUrl = 'https://asaldairy.com';
  static const String _mapsUrl =
      'https://www.google.com/maps/search/?api=1&query=31.444932,73.1559947';

  Future<void> _launchExternalApp(
    BuildContext context, {
    required Uri appUri,
    required Uri fallbackUri,
  }) async {
    try {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (await launchUrl(fallbackUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      if (await launchUrl(fallbackUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final Uri uri =
        Uri.parse('mailto:$email?subject=Inquiry from Asal Dairy App');
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open an email app.')),
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final url = Uri.parse(
      'https://wa.me/$phoneNumber?text=Hello%20I%20want%20to%20order%20milk',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '🥛',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get in Touch',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re here to help you!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Phone
                  _buildContactCard(
                    icon: Icons.phone,
                    title: 'Phone',
                    subtitle: _businessPhoneDisplay,
                    color: Colors.blue,
                    onTap: () => _makePhoneCall(
                        context, '+$_businessPhoneInternational'),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp
                  _buildContactCard(
                    icon: Icons.chat,
                    title: 'WhatsApp',
                    subtitle: _businessPhoneDisplay,
                    color: Colors.green,
                    onTap: () =>
                        _openWhatsApp(context, _businessPhoneInternational),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildContactCard(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'support@asaldairy.com',
                    color: Colors.red,
                    onTap: () => _sendEmail(context, 'support@asaldairy.com'),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _buildContactCard(
                    icon: Icons.location_on,
                    title: 'Address',
                    subtitle:
                        '204 Chak Eden Valley Road, Faisalabad, Punjab, Pakistan',
                    color: Colors.orange,
                    onTap: () => _launchExternalApp(
                      context,
                      appUri: Uri.parse(
                        'geo:31.444932,73.1559947?q=31.444932,73.1559947'
                        '(Asal Dairy Milk Shop)',
                      ),
                      fallbackUri: Uri.parse(_mapsUrl),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Business Hours
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.green[700]),
                              const SizedBox(width: 12),
                              const Text(
                                'Business Hours',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBusinessHour(
                              'Monday - Friday', '7:00 AM - 11:00 PM'),
                          _buildBusinessHour('Saturday', '7:00 AM - 11:00 PM'),
                          _buildBusinessHour('Sunday', '5:30:00 AM - 11:00 PM'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Social Media
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Follow Us',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSocialButton(
                                icon: Icons.facebook,
                                label: 'Facebook',
                                color: const Color(0xFF1877F2),
                                onTap: () => _launchExternalApp(
                                  context,
                                  appUri: Uri.parse(
                                    'fb://facewebmodal/f?href=$_facebookPageUrl',
                                  ),
                                  fallbackUri: Uri.parse(_facebookPageUrl),
                                ),
                              ),
                              _buildSocialButton(
                                icon: Icons.camera_alt,
                                label: 'Instagram',
                                color: const Color(0xFFE4405F),
                                onTap: () => _launchExternalApp(
                                  context,
                                  appUri: Uri.parse(
                                    'instagram://user?username=$_instagramUsername',
                                  ),
                                  fallbackUri: Uri.parse(
                                    'https://www.instagram.com/'
                                    '$_instagramUsername/',
                                  ),
                                ),
                              ),
                              _buildSocialButton(
                                icon: Icons.language,
                                label: 'Website',
                                color: Colors.blue,
                                onTap: () => _launchURL(context, _websiteUrl),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHour(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
