import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../auth/presentation/providers/zeni_auth_providers.dart';

class CanonicalFamilyGatePage extends ConsumerStatefulWidget {
  const CanonicalFamilyGatePage({super.key});

  @override
  ConsumerState<CanonicalFamilyGatePage> createState() =>
      _CanonicalFamilyGatePageState();
}

class _CanonicalFamilyGatePageState
    extends ConsumerState<CanonicalFamilyGatePage> {
  bool _started = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _started = true;
      _error = null;
    });
    final result = await ref
        .read(zeniAuthControllerProvider)
        .prepareCurrentSession();
    if (!mounted || result.isSuccess) return;
    setState(() => _error = result.message);
  }

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return ZeniScaffold(
      child: ZeniPageFrame(
        width: ZeniPageWidth.focus,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error == null) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: ZeniSpacing.lg),
              Center(
                child: Text(
                  'Preparando sua família com segurança...',
                  style: typography.body,
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              Text('Não foi possível continuar', style: typography.display),
              const SizedBox(height: ZeniSpacing.sm),
              Text(_error!, style: typography.body),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniButton(
                label: 'Tentar novamente',
                icon: Icons.refresh_rounded,
                role: ZeniButtonRole.primary,
                mode: ZeniVisualMode.parent,
                onPressed: _prepare,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
