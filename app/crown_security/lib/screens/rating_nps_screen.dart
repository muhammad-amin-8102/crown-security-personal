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
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      // Dummy data
      _currentRating = 4.2;
      _currentNps = 8;
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
    // TODO: Implement API call to submit rating and NPS
    print('Submitting rating: $_currentRating, NPS: $_currentNps');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
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
