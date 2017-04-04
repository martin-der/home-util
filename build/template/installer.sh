#!/usr/bin/env bash



while true; do
	echo "Available locations are :"
	echo "1) '$HOME/bin'"
	echo "2) '/usr/local/bin'"
	echo "3) a custom location"
    read -p "Where do you want to install scripts? " c
    case $c in
        1 ) echo '1'; break;;
        2 ) echo '2'; break;;
        3 ) echo '3'; break;;
        * ) echo "Please answer 1, 2 or 3.";;
    esac
done

while true; do
    read -p "Do you want to init home? " yn
    case $yn in
        [Yy]* ) ./init-home.sh; break;;
        [Nn]* ) ;;
        * ) echo "Please answer yes or no.";;
    esac
done