import 'adc_lab.dart';
import 'addressing_lab.dart';
import 'arch_lab.dart';
import 'clock_lab.dart';
import 'comm_lab.dart';
import 'gpio_lab.dart';
import 'interrupts_lab.dart';
import 'memory_lab.dart';
import 'pins_lab.dart';
import 'pros_cons_lab.dart';
import 'registers_lab.dart';
import 'timer_lab.dart';
import 'topic_lab.dart';

/// The lab for topic [id], 1 to 12 in the paper's order. A new instance each
/// time: a topic opens in its starting state.
TopicLab createLab(int id) => switch (id) {
  1 => ArchLab(),
  2 => MemoryLab(),
  3 => RegistersLab(),
  4 => AddressingLab(),
  5 => PinsLab(),
  6 => GpioLab(),
  7 => ClockLab(),
  8 => TimerLab(),
  9 => ProsConsLab(),
  10 => AdcLab(),
  11 => CommLab(),
  _ => InterruptsLab(),
};
