import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/practice_start_service.dart';

final practiceStartServiceProvider = Provider<PracticeStartService>(
  (ref) => throw StateError('Practice start has not been configured.'),
);
