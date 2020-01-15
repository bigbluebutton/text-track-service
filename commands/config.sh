#!/bin/bash
sudo chmod uog+rwx /usr/bin
working_dir=/var/docker/text-track-service
#working_dir=/home/test2/tts/resque/text-track-service

FILE=/usr/bin/tts-all
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch $FILE
sudo chmod uog+rwx $FILE
echo "ruby $working_dir/commands/tts-all.rb" >> $FILE

FILE=/usr/bin/tts-delete
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch $FILE
sudo chmod uog+rwx $FILE
echo "ruby $working_dir/commands/tts-delete.rb \$1" >> $FILE

FILE=/usr/bin/tts-failed
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch $FILE
sudo chmod uog+rwx $FILE
echo "ruby $working_dir/commands/tts-failed.rb" >> $FILE

FILE=/usr/bin/tts-processed
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch $FILE
sudo chmod uog+rwx $FILE
echo "ruby $working_dir/commands/tts-processed.rb" >> $FILE

FILE=/usr/bin/tts-record
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch $FILE
sudo chmod uog+rwx $FILE
echo "ruby $working_dir/commands/tts-record.rb \$1" >> $FILE

FILE=/usr/bin/tts-secret
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch $FILE
sudo chmod uog+rwx $FILE
echo "ruby $working_dir/commands/tts-secret.rb" >> $FILE

FILE=/usr/bin/tts-delete-all
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch $FILE
sudo chmod uog+rwx $FILE
echo "ruby $working_dir/commands/tts-delete-all.rb" >> $FILE

sudo chmod uog-w /usr/bin