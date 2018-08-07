#!/bin/bash

service rabbitmq-server start

export PATH="/code:$PATH"

# Start the first process
python manage.py runserver 0.0.0.0:8000 &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start manage.py: $status"
  exit $status
fi

# Start the second process
export C_FORCE_ROOT='true'
celery -A galileo_screenshots worker -l info &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start my_second_process: $status"
  exit $status
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux |grep runserver |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep celery |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 ]; then
    echo "Runserver has exited."
    exit 1
  fi
  if [ $PROCESS_2_STATUS -ne 0 ]; then
    echo "Celery has exited."
    exit 1
  fi
done

