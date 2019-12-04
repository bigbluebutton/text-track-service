sudo chmod uog+rwx /bin
#working_dir=/var/docker/text-track-service
working_dir=/home/parthik/tts/final/text-track-service

FILE=/bin/tts-all
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch /bin/tts-all
sudo chmod uog+rwx /bin/tts-all
echo "ruby $working_dir/commands/tts-all.rb" >> /bin/tts-all

FILE=/bin/tts-delete
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch /bin/tts-delete
sudo chmod uog+rwx /bin/tts-delete
echo "ruby $working_dir/commands/tts-delete.rb \$1" >> /bin/tts-delete

FILE=/bin/tts-failed
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch /bin/tts-failed
sudo chmod uog+rwx /bin/tts-failed
echo "ruby $working_dir/commands/tts-failed.rb" >> /bin/tts-failed

FILE=/bin/tts-processed
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch /bin/tts-processed
sudo chmod uog+rwx /bin/tts-processed
echo "ruby $working_dir/commands/tts-processed.rb" >> /bin/tts-processed

FILE=/bin/tts-record
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch /bin/tts-record
sudo chmod uog+rwx /bin/tts-record
echo "ruby $working_dir/commands/tts-record.rb \$1" >> /bin/tts-record

FILE=/bin/tts-secret
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch /bin/tts-secret
sudo chmod uog+rwx /bin/tts-secret
echo "ruby $working_dir/commands/tts-secret.rb" >> /bin/tts-secret

FILE=/bin/tts-delete--all
if test -f "$FILE"; then
    sudo rm "$FILE"
fi
sudo touch /bin/tts-delete-all
sudo chmod uog+rwx /bin/tts-delete-all
echo "ruby $working_dir/commands/tts-delete-all.rb" >> /bin/tts-delete-all
