import 'package:flutter/material.dart';

import '../../../core/services/app_feedback.dart';
import '../../../state/app_store.dart';

class CustomerRateProviderPage extends StatefulWidget {
  const CustomerRateProviderPage({
    super.key,
    required this.store,
    required this.requestId,
    this.forceMode = false,
  });

  final AppStore store;
  final String requestId;
  final bool forceMode;

  @override
  State<CustomerRateProviderPage> createState() =>
      _CustomerRateProviderPageState();
}

class _CustomerRateProviderPageState extends State<CustomerRateProviderPage> {
  final TextEditingController _reviewController = TextEditingController();

  double _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      await widget.store.submitClientRating(
        requestId: widget.requestId,
        rating: _rating,
        review: _reviewController.text.trim(),
      );

      if (!mounted) return;

      AppFeedback.showSuccess(
        context,
        'Merci pour votre evaluation.',
      );

      widget.store.setCustomerTab(0);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildStar(int index) {
    final value = index + 1;
    final selected = _rating >= value;

    return IconButton(
      onPressed: () {
        setState(() => _rating = value.toDouble());
      },
      iconSize: 36,
      icon: Icon(
        selected ? Icons.star : Icons.star_border,
        color: Colors.amber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.store.findRequest(widget.requestId);

    if (request == null) {
      return const Scaffold(
        body: Center(
          child: Text('Demande introuvable'),
        ),
      );
    }

    return PopScope(
      canPop: !widget.forceMode,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.forceMode,
          title: const Text('Evaluer le provider'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 52,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mission terminee',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.providerName ?? 'Provider',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Merci de laisser une evaluation obligatoire avant de continuer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, _buildStar),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _submitting
                              ? 'Envoi...'
                              : 'Envoyer mon evaluation',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}