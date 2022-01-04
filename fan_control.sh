#!/bin/bash
#
# Forked from https://github.com/brezlord/iDRAC7_fan_control
# A simple script to control fan speeds on Dell generation 12/13 PowerEdge servers.
# If the inlet temperature is above 35deg C enable iDRAC dynamic control and exit program.
# If inlet temp is below 35deg C set fan control to manual and set fan speed to predetermined value.

# Variables
IDRAC_IP="192.168.1.120"
IDRAC_USER="myUser"
IDRAC_PASSWORD="myPass"
# Fan speed in %
SPEED0="0x00"
SPEED5="0x05"
SPEED10="0x0a"
SPEED15="0x0f"
SPEED20="0x14"
SPEED25="0x19"
SPEED30="0x1e"
SPEED35="0x23"
INLET_THRESHOLD="35" # iDRAC dynamic control enable thershold
INLET_SENSOR="04h"   # Inlet Temp
CPU1_SENSOR="0Eh"  # CPU 1 Temp
CPU2_SENSOR="0Fh"  # CPU 2 Temp
CPU_THRESHOLD="55"  # Max CPU temp

# Get temperature from iDARC.
TEMPS=$(ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P "$IDRAC_PASSWORD" sdr type temperature)
INLET=$(echo "$TEMPS" | grep $INLET_SENSOR | cut -d"|" -f5 | cut -d" " -f2)
CPU1=$(echo "$TEMPS" | grep $CPU1_SENSOR | cut -d"|" -f5 | cut -d" " -f2)
CPU2=$(echo "$TEMPS" | grep $CPU2_SENSOR | cut -d"|" -f5 | cut -d" " -f2)

# If ambient temperature is above 35deg C enable dynamic control and exit, if below set manual control.
if [ "$INLET" -ge "$INLET_THRESHOLD" ] || [ "$CPU1" -ge "$CPU_THRESHOLD" ] || [ "$CPU2" -ge "$CPU_THRESHOLD" ]
then
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P "$IDRAC_PASSWORD" raw 0x30 0x30 0x01 0x01
  exit 1
else
  # Disable dynamic fan control
  ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P "$IDRAC_PASSWORD" raw 0x30 0x30 0x01 0x00

  # Set fan speed dependant on ambient temperature if inlet temperaturte is below 35deg C.
  # If inlet temperature between 0 and 19deg C then set fans to 15%.
  if [ "$INLET" -le 19 ] && [ "$CPU1" -le 40 ] && [ "$CPU2" -le 40 ]
  then
    ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P "$IDRAC_PASSWORD" raw 0x30 0x30 0x02 0xff $SPEED15

  # If inlet temperature between 20 and 24deg C then set fans to 20%
  elif [ "$INLET" -le 24 ] && [ "$CPU1" -le 45 ] && [ "$CPU2" -le 45 ]
  then
    ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P "$IDRAC_PASSWORD" raw 0x30 0x30 0x02 0xff $SPEED20

  # If inlet temperature between 25 and 29deg C then set fans to 25%
  elif [ "$INLET" -le 29 ] && [ "$CPU1" -le 50 ] && [ "$CPU2" -le 50 ]
  then
    ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P "$IDRAC_PASSWORD" raw 0x30 0x30 0x02 0xff $SPEED25

  # If inlet temperature between 30 and 35deg C then set fans to 30%
  elif [ "$INLET" -le 35 ] && [ "$CPU1" -le 55 ] && [ "$CPU2" -le 55 ]
  then
    ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P "$IDRAC_PASSWORD" raw 0x30 0x30 0x02 0xff $SPEED30
  fi
fi
