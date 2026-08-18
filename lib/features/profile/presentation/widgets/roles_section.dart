import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter/material.dart';

class RolesSection extends StatefulWidget {
  final bool isRider;
  final bool isDriver;
  final String? currentPreference;

  const RolesSection({
    super.key,
    required this.isRider,
    required this.isDriver,
    this.currentPreference,
  });

  @override
  State<RolesSection> createState() => _RolesSectionState();
}

class _RolesSectionState extends State<RolesSection> {
  bool _isExpanded = false;

  bool get _canDeactivate => widget.isRider && widget.isDriver;

  String _computeNewPreference(String action, String role) {
    final current = widget.currentPreference;
    if (action == 'activate') {
      if (role == 'rider') {
        if (current == 'drive') return 'both';
        return 'ride';
      } else {
        if (current == 'ride') return 'both';
        return 'drive';
      }
    } else {
      if (role == 'rider') return 'drive';
      return 'ride';
    }
  }

  Future<void> _updateRole(String action, String role) async {
    final newPreference = _computeNewPreference(action, role);
    try {
      await sl<ProfileRepository>().updateTravelPreference(newPreference);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Roles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Image.asset(
                    'assets/images/next.png',
                    width: 9,
                    height: 18,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage ride preferences',
          style: TextStyle(
            color: AppColors.subheadingGrey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.285,
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    roleName: 'Rider',
                    isActive: widget.isRider,
                    canDeactivate: _canDeactivate,
                    onActivate: () => _updateRole('activate', 'rider'),
                    onDeactivate: () => _updateRole('deactivate', 'rider'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleCard(
                    roleName: 'Driver',
                    isActive: widget.isDriver,
                    canDeactivate: _canDeactivate,
                    onActivate: () => _updateRole('activate', 'driver'),
                    onDeactivate: () => _updateRole('deactivate', 'driver'),
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String roleName;
  final bool isActive;
  final bool canDeactivate;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const _RoleCard({
    required this.roleName,
    required this.isActive,
    required this.canDeactivate,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roleName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'Current role' : 'Not added',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8A8A8A),
            ),
          ),
          const SizedBox(height: 14),
          isActive
              ? _buildActivePill(canDeactivate)
              : _buildActivateButton(),
        ],
      ),
    );
  }

  Widget _buildActivePill(bool canDeactivate) {
    return GestureDetector(
      onTap: canDeactivate ? onDeactivate : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD8D8D8)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Active',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }

  Widget _buildActivateButton() {
    return GestureDetector(
      onTap: onActivate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Become a $roleName',
            maxLines: 1,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
