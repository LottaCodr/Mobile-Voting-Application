import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../widgets/common.dart';

class ServiceUnavailableScreen extends StatelessWidget {
  const ServiceUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageFrame(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(),
                const SizedBox(height: 40),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.redPale, shape: BoxShape.circle),
                  child: const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 31),
                ),
                const SizedBox(height: 20),
                Text(
                  'The secure service could not start.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'CivicVote did not fall back to a local ballot because a Supabase configuration was supplied. Check the project URL and publishable key, then restart the app.',
                  style: TextStyle(color: AppColors.inkMuted, height: 1.5),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.blueDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No ballot data is stored on this device while the secure backend is unavailable.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.navy,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'After correcting the configuration, restart the app to establish a fresh secure session.',
                  style: TextStyle(color: AppColors.inkMuted, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
