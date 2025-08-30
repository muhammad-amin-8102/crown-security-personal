import 'package:crown_security/core/api.dart';
import 'package:flutter/material.dart';

class RatingNpsScreen extends StatefulWidget {
  const RatingNpsScreen({super.key});

  @override
  State<RatingNpsScreen> createState() => _RatingNpsScreenState();
}

class _RatingNpsScreenState extends State<RatingNpsScreen> {
  double _currentRating = 3.0;
  int? _currentNps;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
  final response = await Api.dio.get('/ratings', queryParameters: {'siteId': siteId});
      final list = response.data as List?;
      final latest = (list != null && list.isNotEmpty) ? list[0] : null;
      if (latest != null) {
        setState(() {
          final ratingVal = latest['rating'] ?? latest['rating_value'];
          _currentRating = (ratingVal as num?)?.toDouble() ?? 3.0;
          final nps = latest['npsScore'] ?? latest['nps_score'];
          _currentNps = (nps is String) ? int.tryParse(nps) : (nps as int?);
        });
      }
    } catch (e) {
      _error = 'Failed to load rating data.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_currentNps == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an NPS score.')),
      );
      return;
    }

    try {
      final siteId = await Api.storage.read(key: 'site_id');
      if (siteId == null) {
        throw Exception('Site ID not found');
      }
      final now = DateTime.now();
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      await Api.dio.post('/ratings', data: {
        'site_id': siteId,
        'month': monthStr,
        'rating_value': _currentRating,
        'nps_score': _currentNps,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feedback.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating & NPS'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRatingCard(),
          const SizedBox(height: 24),
          _buildNpsCard(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitRating,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Rate our service',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _currentRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentRating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            Text(
              'Your Rating: $_currentRating',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNpsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'How likely are you to recommend us?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(11, (index) {
                return ChoiceChip(
                  label: Text('$index'),
                  selected: _currentNps == index,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentNps = index;
                      });
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: _currentNps == index ? Colors.white : Colors.black,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Not at all likely', style: Theme.of(context).textTheme.bodySmall),
                Text('Extremely likely', style: Theme.of(context).textTheme.bodySmall),
              ],
            )
          ],
        ),
      ),
    );
  }
}
