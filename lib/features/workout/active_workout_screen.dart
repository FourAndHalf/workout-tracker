import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../program/program_providers.dart';
import 'providers/active_workout_provider.dart';
import 'widgets/set_logger_card.dart';
import 'widgets/cumulative_counter.dart';
import 'widgets/rest_timer_widget.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String dayId;

  const ActiveWorkoutScreen({super.key, required this.dayId});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(currentProgramProvider);
    final workoutState = ref.watch(activeWorkoutProvider(widget.dayId));
    final workoutNotifier = ref.read(
      activeWorkoutProvider(widget.dayId).notifier,
    );

    return programAsync.when(
      data: (program) {
        final week = program.weeks.first;
        final day = week.days.firstWhere(
          (d) => d.id == widget.dayId,
          orElse: () => week.days.first,
        );

        if (workoutState.dayModel == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            workoutNotifier.initDay(day);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Elapsed: ${_formatElapsed(_elapsedSeconds)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'FINISH',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await workoutNotifier.finishWorkout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout Session Completed! 🎉'),
                      ),
                    );
                    context.go('/');
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: day.blocks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, blockIndex) {
                    final block = day.blocks[blockIndex];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Block ${blockIndex + 1}: ${block.name} (${block.type})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        ...block.exercises.map((exercise) {
                          if (exercise.logMode == 'cumulative') {
                            final chunks =
                                workoutState.restPauseChunks[exercise.id] ?? [];
                            return CumulativeCounter(
                              targetReps: exercise.repTarget ?? 100,
                              loggedChunks: chunks,
                              onAddChunk: (chunkReps) {
                                workoutNotifier.addRestPauseChunk(
                                  exercise: exercise,
                                  block: block,
                                  chunkReps: chunkReps,
                                );
                              },
                            );
                          } else {
                            final loggedSets =
                                workoutState.loggedSets[exercise.id] ?? [];
                            final currentSetNum = loggedSets.length + 1;

                            return SetLoggerCard(
                              exercise: exercise,
                              currentSetNumber: currentSetNum,
                              loggedSets: loggedSets,
                              onLogSet:
                                  ({
                                    weight,
                                    reps,
                                    hitFailure = false,
                                    durationSeconds,
                                  }) {
                                    workoutNotifier.logSet(
                                      exercise: exercise,
                                      block: block,
                                      weight: weight,
                                      reps: reps,
                                      hitFailure: hitFailure,
                                      durationSeconds: durationSeconds,
                                    );
                                  },
                            );
                          }
                        }),
                      ],
                    );
                  },
                ),
              ),

              if (workoutState.isResting)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: RestTimerWidget(
                    initialSeconds: workoutState.restSeconds,
                    onComplete: () {
                      workoutNotifier.dismissRestTimer();
                    },
                    onDismiss: () {
                      workoutNotifier.dismissRestTimer();
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
