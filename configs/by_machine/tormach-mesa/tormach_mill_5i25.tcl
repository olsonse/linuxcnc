########################################################################
#
# Tormach PCNC mill HAL config for 5i25 I/O
# These machines should be supported:  440, 770, 1100-[1,2,3]
#

loadrt $::KINS(KINEMATICS)
loadrt $::EMCMOT(EMCMOT) servo_period_nsec=$::EMCMOT(SERVO_PERIOD) num_joints=$::KINS(JOINTS) num_dio=64 num_aio=64
loadrt hostmot2
loadrt hm2_pci config=" num_encoders=0 num_pwmgens=1 num_3pwmgens=0 num_stepgens=5 "
loadrt estop_latch
# we need 2 toggles/gearchangers:  1 for belt, 1 for "speeder is attached"
loadrt toggle names=belt-toggle,speeder-toggle
loadrt gearchange count=2
loadrt mult2 names=mult2.speeder,mult2.sxp.jog-increment,spindle-drive.scale
loadrt offset names=spindle-drive.rpm-offset,spindle-drive.drive-offset
loadrt not names=higear-not-used,prog-not-idle,axis3-not-homing
loadrt xor2 names=probe-active-hi-lo
loadrt debounce cfg=5
loadrt pid num_chan=4
loadrt and2 names=probe-enable-input,and2.sxp-x-pos,and2.sxp-x-neg,and2.sxp-y-pos,and2.sxp-y-neg,and2.sxp-z-pos,and2.sxp-z-neg
loadrt limit2 names=spindle-ramp




########################################################################
# servo thread
addf hm2_5i25.0.read    servo-thread
addf hm2_5i25.0.write   servo-thread
#addf hm2_5i25.0.pet_watchdog servo-thread
addf motion-command-handler servo-thread
addf motion-controller  servo-thread
addf estop-latch.0      servo-thread
addf belt-toggle        servo-thread
addf speeder-toggle     servo-thread
addf gearchange.0       servo-thread
addf gearchange.1       servo-thread
addf mult2.speeder      servo-thread
addf higear-not-used    servo-thread
addf prog-not-idle      servo-thread
addf axis3-not-homing   servo-thread
addf probe-active-hi-lo servo-thread
addf debounce.0         servo-thread
addf pid.0.do-pid-calcs servo-thread
addf pid.1.do-pid-calcs servo-thread
addf pid.2.do-pid-calcs servo-thread
addf pid.3.do-pid-calcs servo-thread
addf probe-enable-input servo-thread
addf spindle-ramp       servo-thread
addf spindle-drive.rpm-offset.update-output   servo-thread
addf spindle-drive.scale                      servo-thread
addf spindle-drive.drive-offset.update-output servo-thread


########################################################################
# noise debounce for home switches and estop
setp debounce.0.delay 1


########################################################################
# 5i25 watchdog timeout
# 10 milliseconds (~10 times the servo loop period)
setp hm2_5i25.0.watchdog.timeout_ns 10*$::EMCMOT(SERVO_PERIOD)


########################################################################
# 5i25 for 770, 1100 machines
#
# Configuration pin-out:
#
#    Mill Function   Pin#    I/O     Pri. func    Sec. func    Chan      Pin func     Pin Dir
#
#    Spindle Speed    1        0     IOPort       StepGen       4        Step/Table1    (Out)
#    Coolant         14        1     IOPort       None                                  (Out)
#    X Direction      2        2     IOPort       StepGen       0        Dir/Table2     (Out)
#    Estop Reset     15        3     IOPort       None                                  (In)
#    X Step           3        4     IOPort       StepGen       0        Step/Table1    (Out)
#    Spindle Dir     16        5     IOPort       None                                  (Out)
#    Y Direction      4        6     IOPort       StepGen       1        Dir/Table2     (Out)
#    Charge Pump     17        7     IOPort       PWM           0        PWM            (Out)
#    Y Step           5        8     IOPort       StepGen       1        Step/Table1    (Out)
#    Z Direction      6        9     IOPort       StepGen       2        Dir/Table2     (Out)
#    Z Step           7       10     IOPort       StepGen       2        Step/Table1    (Out)
#    A Direction      8       11     IOPort       StepGen       3        Dir/Table2     (Out)
#    A Step           9       12     IOPort       StepGen       3        Step/Table1    (Out)
#    X Limit         10       13     IOPort       None                                  (In)
#    Y Limit         11       14     IOPort       None                                  (In)
#    Z Limit         12       15     IOPort       None                                  (In)
#    Probe In        13       16     IOPort       None                                  (In)
#
#
# 5i25 for 440 machines
#
# Configuration pin-out:
#
#    Mill Function   Pin#    I/O     Pri. func    Sec. func    Chan      Pin func     Pin Dir
#
#    Spindle Enable   1      0   IOPort       None
#    Spindle Speed   14      1   IOPort       PWM              0
#    X Step           2      2   IOPort       StepGen          0        Step            (Out)
#    Estop Reset     15      3   IOPort       None                                      (In)
#    X Direction      3      4   IOPort       StepGen          0        Dir             (Out)
#    Charge Pump     16      5   IOPort       StepGen          4        Step            (Out)
#    Y Step           4      6   IOPort       StepGen          1        Step            (Out)
#    Coolant         17      7   IOPort       None                                      (Out)
#    Y Direction      5      8   IOPort       StepGen          1        Dir             (Out)
#    Z Step           6      9   IOPort       StepGen          2        Step            (Out)
#    Z Direction      7     10   IOPort       StepGen          2        Dir             (Out)
#    A Step           8     11   IOPort       StepGen          3        Step            (Out)
#    A Direction      9     12   IOPort       StepGen          3        Dir             (Out)
#    X Limit         10     13   IOPort       None                                      (In)
#    Y Limit         11     14   IOPort       None                                      (In)
#    Z Limit         12     15   IOPort       None                                      (In)
#    Probe In        13     16   IOPort       QCountIdx        0        Idx             (In)

########################################################################
# Spindle speed control
#

if { $::EMC(MACHINE) == "440" } {
  setp hm2_5i25.0.pwmgen.00.output-type 1
  setp hm2_5i25.0.pwmgen.pwm_frequency  10
  setp hm2_5i25.0.pwmgen.00.scale       1.0

  # set spindle enable pin to output
  # P3 pin 1 gpio 000
  setp hm2_5i25.0.gpio.000.is_output 1
  # enable is active low
  #setp hm2_5i25.0.gpio.000.invert_output 1

  # connect motion spindle enable to stepgen enable and spindle comp
  net spindle-on        motion.spindle-on     => hm2_5i25.0.pwmgen.00.enable \
                                              => hm2_5i25.0.gpio.000.out

  # limit rate of PWM change sent to drive by limiting what the spindle comp is told
  # this will likely break the "spindle-at-speed" logic the spindle comp - must test/fix

  # 440 spindle drive CANNOT have DIR change while ENA is active or it smokes itself
  # insert a comp between motion and the gpios to insure DIR never changes while ENA is active
  # connect motion spindle enable to pwmgen enable and spindle comp

  net spindle-drive.out     spindle-drive.drive-offset.out   => hm2_5i25.0.pwmgen.00.value
} else {
  # type 1 velocity control mode
  setp hm2_5i25.0.stepgen.04.control-type 1

  # step/dir
  # type 2 quadrature output for 50% duty cycle
  setp hm2_5i25.0.stepgen.04.step_type 2
  # scaling is done via S(...) lambda function implemented below
  setp hm2_5i25.0.stepgen.04.position-scale 1.0
  FIXME:  put this in the new/correct units of counts
  setp hm2_5i25.0.stepgen.04.maxaccel $::SPINDLE(MAX_ACCELERATION)
  setp hm2_5i25.0.stepgen.04.maxvel $::SPINDLE(DRIVE_MAX)

  # stepspace in nanoseconds
  setp hm2_5i25.0.stepgen.04.stepspace 0

  # steplen in nanoseconds (10 microseconds)
  setp hm2_5i25.0.stepgen.04.steplen 10000

  # connect motion spindle enable to stepgen enable and spindle comp
  net spindle-on        motion.spindle-on     => hm2_5i25.0.stepgen.04.enable

  # spindle direction
  # P3 pin 16 gpio 005
  setp hm2_5i25.0.gpio.005.is_output 1
  net spindle-cw motion.spindle-forward => hm2_5i25.0.gpio.005.out

  net spindle-drive.out     spindle-drive.drive-offset.out   => hm2_5i25.0.stepgen.04.velocity-cmd
}

# spindle-ramp limits the slew of the motor speed.  This should be in
# reference to the lower speed range, since everything will be converted to a
# factor of the motor speed.
setp spindle-ramp.maxv        $::SPINDLE(LO_RANGE_MAX) / $::SPINDLE(SECONDS_TO_MAX_RPM)


##### Things to help interact with user
# no filtering for user belt change button
setp belt-toggle.debounce 0
# no filtering for user speeder change button
setp speeder-toggle.debounce 0

setp gearchange.0.min1    $::SPINDLE(LO_RANGE_MIN)
setp gearchange.0.max1    $::SPINDLE(LO_RANGE_MAX)
setp gearchange.0.min2    $::SPINDLE(HI_RANGE_MIN)
setp gearchange.0.max2    $::SPINDLE(HI_RANGE_MAX)
setp gearchange.0.scale2  "$::SPINDLE(HI_RANGE_MAX) / $::SPINDLE(LO_RANGE_MAX)"

setp gearchange.1.min1    1
setp gearchange.1.max1    1
setp gearchange.1.min2    $::SPINDLE(SPEEDER_DIVISOR)
setp gearchange.1.max2    $::SPINDLE(SPEEDER_DIVISOR)
setp gearchange.1.scale2  $::SPINDLE(SPEEDER_DIVISOR)
# static value, because we only use scaler
setp gearchange.1.speed-in 1.0
net spindle-by-speeder    gearchange.1.speed-out      => mult2.speeder.in0

# we're not controlling the direction with the gearchanger, so reverse isn't set
# and the dir-in and dir-out pins aren't linked
net spindle-speed-total   motion.spindle-speed-out    => mult2.speeder.in1
net spindle-speed-raw     mult2.speeder.out           => gearchange.0.speed-in
# connect motion speed-out to input of spindle-ramp
net spindle-speed-request gearchange.0.speed-out      => spindle-ramp.in
# need to implement something like this function to convert speed to the correct
# duty-cycle range for the PWM:
# S = lambda x : (x - RMIN) * (DRIVE_MAX - DRIVE_MIN)/(RMAX - RMIN) + DRIVE_MIN
setp spindle-drive.rpm-offset.offset    -$::SPINDLE(LO_RANGE_MIN)
setp spindle-drive.scale.in0           "($::SPINDLE(DRIVE_MAX) -
                                         $::SPINDLE(DRIVE_MIN))
                                      / ($::SPINDLE(LO_RANGE_MAX) -
                                         $::SPINDLE(LO_RANGE_MIN))"
setp spindle-drive.drive-offset.offset  +$::SPINDLE(DRIVE_MIN)

net spindle-speed-ramp    spindle-ramp.out              => spindle-drive.rpm-offset.in
net spindle-speed-offs    spindle-drive.rpm-offset.out  => spindle-drive.scale.in1
net spindle-speed-scale   spindle-drive.scale.out       => spindle-drive.drive-offset.in


########################################################################
# Coolant
if { $::EMC(MACHINE) == "440" } {
  # P3 pin 17 gpio 007

  setp hm2_5i25.0.gpio.007.is_output        1
  setp hm2_5i25.0.gpio.007.is_opendrain     0
  net coolant-flood =>  hm2_5i25.0.gpio.007.out
  net coolant-flood <=  iocontrol.0.coolant-flood
} else {
  # P3 pin 14 gpio 001

  setp hm2_5i25.0.gpio.001.is_output        1
  setp hm2_5i25.0.gpio.001.is_opendrain     0
  net coolant-flood =>  hm2_5i25.0.gpio.001.out
  net coolant-flood <=  iocontrol.0.coolant-flood
}


########################################################################
# Charge pump
# pin set by 5i25 configuration
if { $::EMC(MACHINE) == "440" } {
  # type 1 velocity control mode
  setp hm2_5i25.0.stepgen.04.control-type 1

  # step/dir
  # type 2 quadrature output for 50% duty cycle
  setp hm2_5i25.0.stepgen.04.step_type 2

  # no scaling 1:1, max accel
  setp hm2_5i25.0.stepgen.04.position-scale 1.0
  setp hm2_5i25.0.stepgen.04.maxaccel 0

  # stepspace in nanoseconds
  setp hm2_5i25.0.stepgen.04.stepspace 0

  # steplen in nanoseconds (10 microseconds)
  setp hm2_5i25.0.stepgen.04.steplen 10000

  # charge pump frequency = 10k
  setp hm2_5i25.0.stepgen.04.velocity-cmd 10000
} else {
  # P3 pin 17 gpio 007
  # dc = (value/scale)

  setp hm2_5i25.0.pwmgen.00.output-type 1
  setp hm2_5i25.0.pwmgen.pwm_frequency 500
  setp hm2_5i25.0.pwmgen.00.scale 100
  setp hm2_5i25.0.pwmgen.00.value 5
}


########################################################################
# E stop
# P3 pin 15 gpio 003

# estop noise debounce
# use this line with a machine attached
net machine-ok-raw <= hm2_5i25.0.gpio.003.in_not => debounce.0.3.in

# use the setp line below without a machine attached
# this isn't useful unless a properly flashed 5i25 is present
# no machine attached
#setp debounce.0.3.in 1

net machine-ok debounce.0.3.out => estop-latch.0.ok-in

net estop estop-latch.0.ok-out => iocontrol.0.emc-enable-in
net estop-reset iocontrol.0.user-request-enable => estop-latch.0.reset
net estop-out <= iocontrol.0.user-enable-out

if { $::EMC(MACHINE) == "440" } {
  net estop => hm2_5i25.0.stepgen.04.enable
} else {
  net estop => hm2_5i25.0.pwmgen.00.enable
}


########################################################################
# Probe
# P3 pin 13 gpio 016
setp hm2_5i25.0.gpio.016.is_output 0
net probe-in        hm2_5i25.0.gpio.016.in debounce.0.4.in

net probe-active-high probe-active-hi-lo.in0
net probe-debounced   debounce.0.4.out       probe-active-hi-lo.in1

# connect 4th axis home input directly to debounced accessory input
net probe-debounced   joint.3.home-sw-in

# probe active hi-low output signal to AND input with probe-enable signal
net probe-hi-lo       probe-active-hi-lo.out probe-enable-input.in1

# do this to only disable the probe input during 4th axis homing
net ax3-is-homing     joint.3.homing         axis3-not-homing.in
net ax3-not-homing    axis3-not-homing.out   probe-enable-input.in0

net probe-input       probe-enable-input.out motion.probe-input


# *** SET THIS TO DEFINE LOGIC LEVEL TO HIGH (or LOW) ***
# If you install a device that uses the A joint, you should set this so that the signal is
# correct for the limit switch on that device.
sets probe-active-high True

########################################################################
# X axis
# step/dir
setp hm2_5i25.0.stepgen.00.step_type 0
# velocity control
setp hm2_5i25.0.stepgen.00.control-type 1

# scaling for position feedback, position command, and velocity command, in steps per length unit.
# converts from counts to position units. position = counts / position_scale
setp hm2_5i25.0.stepgen.00.position-scale $::JOINT_0(SCALE)

# stepper driver timing parameters
setp hm2_5i25.0.stepgen.00.steplen $::JOINT_0(STEPLEN)
setp hm2_5i25.0.stepgen.00.stepspace $::JOINT_0(STEPSPACE)
setp hm2_5i25.0.stepgen.00.dirhold $::JOINT_0(DIRHOLD)
setp hm2_5i25.0.stepgen.00.dirsetup $::JOINT_0(DIRSETUP)

# 20 % higher
setp hm2_5i25.0.stepgen.00.maxvel 1.2*$::JOINT_0(MAX_VELOCITY)
setp hm2_5i25.0.stepgen.00.maxaccel 1.2*$::JOINT_0(MAX_ACCELERATION)

# axis enable chain
newsig emcmot.00.enable bit
sets emcmot.00.enable FALSE

net emcmot.00.enable <= joint.0.amp-enable-out
net emcmot.00.enable => hm2_5i25.0.stepgen.00.enable pid.0.enable

# position command and feedback
net emcmot.00.pos-cmd joint.0.motor-pos-cmd => pid.0.command
net emcmot.00.vel-cmd joint.0.vel-cmd => pid.0.command-deriv
net motor.00.pos-fb <= hm2_5i25.0.stepgen.00.position-fb joint.0.motor-pos-fb pid.0.feedback
net motor.00.command pid.0.output hm2_5i25.0.stepgen.00.velocity-cmd
setp pid.0.error-previous-target true

# PID parameters
setp pid.0.Pgain $::JOINT_0(P)
setp pid.0.Igain $::JOINT_0(I)
setp pid.0.Dgain $::JOINT_0(D)
setp pid.0.bias $::JOINT_0(BIAS)
setp pid.0.FF0 $::JOINT_0(FF0)
setp pid.0.FF1 $::JOINT_0(FF1)
setp pid.0.FF2 $::JOINT_0(FF2)
setp pid.0.deadband $::JOINT_0(DEADBAND)
setp pid.0.maxoutput $::JOINT_0(MAX_OUTPUT)
setp pid.0.maxerror $::JOINT_0(MAX_ERROR)

# P3 pin 3 gpio 004
# X step
setp hm2_5i25.0.gpio.004.invert_output 1

########################################################################
# Y axis
# step/dir
setp hm2_5i25.0.stepgen.01.step_type 0
# velocity control
setp hm2_5i25.0.stepgen.01.control-type 1

# scaling for position feedback, position command, and velocity command, in steps per length unit.
# converts from counts to position units. position = counts / position_scale
setp hm2_5i25.0.stepgen.01.position-scale $::JOINT_1(SCALE)

# stepper driver timing parameters
setp hm2_5i25.0.stepgen.01.steplen $::JOINT_1(STEPLEN)
setp hm2_5i25.0.stepgen.01.stepspace $::JOINT_1(STEPSPACE)
setp hm2_5i25.0.stepgen.01.dirhold $::JOINT_1(DIRHOLD)
setp hm2_5i25.0.stepgen.01.dirsetup $::JOINT_1(DIRSETUP)

# 20 % higher
setp hm2_5i25.0.stepgen.01.maxvel 1.2*$::JOINT_1(MAX_VELOCITY)
setp hm2_5i25.0.stepgen.01.maxaccel 1.2*$::JOINT_1(MAX_ACCELERATION)

# axis enable chain
newsig emcmot.01.enable bit
sets emcmot.01.enable FALSE

net emcmot.01.enable <= joint.1.amp-enable-out
net emcmot.01.enable => hm2_5i25.0.stepgen.01.enable pid.1.enable

# position command and feedback
net emcmot.01.pos-cmd joint.1.motor-pos-cmd => pid.1.command
net emcmot.01.vel-cmd joint.1.vel-cmd => pid.1.command-deriv
net motor.01.pos-fb <= hm2_5i25.0.stepgen.01.position-fb joint.1.motor-pos-fb pid.1.feedback
net motor.01.command pid.1.output hm2_5i25.0.stepgen.01.velocity-cmd
setp pid.1.error-previous-target true

# PID parameters
setp pid.1.Pgain $::JOINT_1(P)
setp pid.1.Igain $::JOINT_1(I)
setp pid.1.Dgain $::JOINT_1(D)
setp pid.1.bias $::JOINT_1(BIAS)
setp pid.1.FF0 $::JOINT_1(FF0)
setp pid.1.FF1 $::JOINT_1(FF1)
setp pid.1.FF2 $::JOINT_1(FF2)
setp pid.1.deadband $::JOINT_1(DEADBAND)
setp pid.1.maxoutput $::JOINT_1(MAX_OUTPUT)
setp pid.1.maxerror $::JOINT_1(MAX_ERROR)

# P3 pin 5 gpio 008
# Y step
setp hm2_5i25.0.gpio.008.invert_output 1

########################################################################
# Z axis
# step/dir
setp hm2_5i25.0.stepgen.02.step_type 0
# velocity control
setp hm2_5i25.0.stepgen.02.control-type 1

# scaling for position feedback, position command, and velocity command, in steps per length unit.
# converts from counts to position units. position = counts / position_scale
setp hm2_5i25.0.stepgen.02.position-scale $::JOINT_2(SCALE)

# stepper driver timing parameters
setp hm2_5i25.0.stepgen.02.steplen $::JOINT_2(STEPLEN)
setp hm2_5i25.0.stepgen.02.stepspace $::JOINT_2(STEPSPACE)
setp hm2_5i25.0.stepgen.02.dirhold $::JOINT_2(DIRHOLD)
setp hm2_5i25.0.stepgen.02.dirsetup $::JOINT_2(DIRSETUP)

# 20 % higher
setp hm2_5i25.0.stepgen.02.maxvel 1.2*$::JOINT_2(MAX_VELOCITY)
setp hm2_5i25.0.stepgen.02.maxaccel 1.2*$::JOINT_2(MAX_ACCELERATION)

# axis enable chain
newsig emcmot.02.enable bit
sets emcmot.02.enable FALSE

net emcmot.02.enable <= joint.2.amp-enable-out
net emcmot.02.enable => hm2_5i25.0.stepgen.02.enable pid.2.enable

# position command and feedback
net emcmot.02.pos-cmd joint.2.motor-pos-cmd => pid.2.command
net emcmot.02.vel-cmd joint.2.vel-cmd => pid.2.command-deriv
net motor.02.pos-fb <= hm2_5i25.0.stepgen.02.position-fb joint.2.motor-pos-fb pid.2.feedback
net motor.02.command pid.2.output hm2_5i25.0.stepgen.02.velocity-cmd
setp pid.2.error-previous-target true

# PID parameters
setp pid.2.Pgain $::JOINT_2(P)
setp pid.2.Igain $::JOINT_2(I)
setp pid.2.Dgain $::JOINT_2(D)
setp pid.2.bias $::JOINT_2(BIAS)
setp pid.2.FF0 $::JOINT_2(FF0)
setp pid.2.FF1 $::JOINT_2(FF1)
setp pid.2.FF2 $::JOINT_2(FF2)
setp pid.2.deadband $::JOINT_2(DEADBAND)
setp pid.2.maxoutput $::JOINT_2(MAX_OUTPUT)
setp pid.2.maxerror $::JOINT_2(MAX_ERROR)

# P3 pin 7 gpio 010
# Z step
setp hm2_5i25.0.gpio.010.invert_output 1

########################################################################
# A axis
# step/dir
setp hm2_5i25.0.stepgen.03.step_type 0
# velocity control
setp hm2_5i25.0.stepgen.03.control-type 1

# scaling for position feedback, position command, and velocity command, in steps per length unit.
# converts from counts to position units. position = counts / position_scale
setp hm2_5i25.0.stepgen.03.position-scale $::JOINT_3(SCALE)

# stepper driver timing parameters
setp hm2_5i25.0.stepgen.03.steplen $::JOINT_3(STEPLEN)
setp hm2_5i25.0.stepgen.03.stepspace $::JOINT_3(STEPSPACE)
setp hm2_5i25.0.stepgen.03.dirhold $::JOINT_3(DIRHOLD)
setp hm2_5i25.0.stepgen.03.dirsetup $::JOINT_3(DIRSETUP)

# 20 % higher
setp hm2_5i25.0.stepgen.03.maxvel 1.2*$::JOINT_3(MAX_VELOCITY)
setp hm2_5i25.0.stepgen.03.maxaccel 1.2*$::JOINT_3(MAX_ACCELERATION)

# axis enable chain
newsig emcmot.03.enable bit
sets emcmot.03.enable FALSE

net emcmot.03.enable <= joint.3.amp-enable-out
net emcmot.03.enable => hm2_5i25.0.stepgen.03.enable pid.3.enable

# position command and feedback
net emcmot.03.pos-cmd joint.3.motor-pos-cmd => pid.3.command
net emcmot.03.vel-cmd joint.3.vel-cmd => pid.3.command-deriv
net motor.03.pos-fb <= hm2_5i25.0.stepgen.03.position-fb joint.3.motor-pos-fb pid.3.feedback
net motor.03.command pid.3.output hm2_5i25.0.stepgen.03.velocity-cmd
setp pid.3.error-previous-target true

# PID parameters
setp pid.3.Pgain $::JOINT_3(P)
setp pid.3.Igain $::JOINT_3(I)
setp pid.3.Dgain $::JOINT_3(D)
setp pid.3.bias $::JOINT_3(BIAS)
setp pid.3.FF0 $::JOINT_3(FF0)
setp pid.3.FF1 $::JOINT_3(FF1)
setp pid.3.FF2 $::JOINT_3(FF2)
setp pid.3.deadband $::JOINT_3(DEADBAND)
setp pid.3.maxoutput $::JOINT_3(MAX_OUTPUT)
setp pid.3.maxerror $::JOINT_3(MAX_ERROR)

# P3 pin 9 gpio 012
# A step
setp hm2_5i25.0.gpio.012.invert_output 1


########################################################################
# home switches

# must noise debounce inputs - otherwise coolant on/off can cause spurious estops
net home-limit-x-raw <= hm2_5i25.0.gpio.013.in => debounce.0.0.in
net home-limit-y-raw <= hm2_5i25.0.gpio.014.in => debounce.0.1.in
net home-limit-z-raw <= hm2_5i25.0.gpio.015.in => debounce.0.2.in
#setp debounce.0.0.in 1
#setp debounce.0.1.in 1
#setp debounce.0.2.in 1

net home-limit-x debounce.0.0.out
net home-limit-y debounce.0.1.out
net home-limit-z debounce.0.2.out

net home-limit-x => joint.0.home-sw-in
net home-limit-x => joint.0.neg-lim-sw-in
net home-limit-x => joint.0.pos-lim-sw-in

net home-limit-y => joint.1.home-sw-in
net home-limit-y => joint.1.neg-lim-sw-in
net home-limit-y => joint.1.pos-lim-sw-in

net home-limit-z => joint.2.home-sw-in
net home-limit-z => joint.2.neg-lim-sw-in
net home-limit-z => joint.2.pos-lim-sw-in

########################################################################
#
# tool change
#

# # loopback tool-change to tool-changed
# net tool-change iocontrol.0.tool-change => iocontrol.0.tool-changed
#
# # loopback prepare to prepared
# net tool-prepare-loopback iocontrol.0.tool-prepare => iocontrol.0.tool-prepared

# we don't have the ATD, we only do manual tool change
loadusr -W hal_manualtoolchange
net tool-change iocontrol.0.tool-change => hal_manualtoolchange.change
net tool-changed iocontrol.0.tool-changed <= hal_manualtoolchange.changed
net tool-number iocontrol.0.tool-prep-number => hal_manualtoolchange.number
net tool-prepare-loopback iocontrol.0.tool-prepare => iocontrol.0.tool-prepared
