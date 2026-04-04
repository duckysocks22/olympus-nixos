{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.carddump = pkgs.writeShellScriptBin "carddump" ''
      if [ "$(find /$HOME/Pictures/carddump/jpg -type f | wc -l)" -gt 0 ]; then
        echo "Please clear directories before continuing!"
        exit

      elif [ "$(find /$HOME/Pictures/carddump/cr2 -type f | wc -l)" -gt 0 ]; then
        echo "Please clear directories before continuing!"
      fi

      echo "Enter SD device name"
      read sd
      echo "Mounting..."
      sudo mount $sd /media/sd

      if test -d "/$HOME/Pictures/carddump"; then
        echo "carddump dir exists"
      else
        echo "creating carddump dir"
        mkdir /$HOME/Pictures/carddump
      fi
      
      if test -d "/$HOME/Pictures/carddump/jpg"; then
        echo "carddump/jpg dir exists"
      else
        echo "creating carddump/jpg dir"
        mkdir /$HOME/Pictures/carddump/jpg
      fi

      if test -d "/$HOME/Pictures/carddump/cr2"; then
        echo "carddump/cr2 dir exists"
      else
        echo "creating carddump/cr2 dir"
        mkdir /home/$USER/Pictures/carddump/cr2
      fi

      if [ -d "/media/sd/DCIM/100CANON" ]; then
        echo "Found picture directory"
      else
        echo "DCIM/100CANON not found"
        exit
      fi

      cd /media/sd/DCIM/100CANON || exit
      
      find ./ -name '*.JPG' -exec cp -v "{}" /$HOME/Pictures/carddump/jpg \;
      find ./ -name '*.CR2' -exec cp -v "{}" /$HOME/Pictures/carddump/cr2 \;

      read -p "Do you want to clear the mounted SD Card? [Y/n/c] " response

      case "$response" in
        [Yy]* ) echo "Proceeding..."
          sudo rm -Rf /media/sd/DCIM/100CANON/*
        ;;
        [Nn]* ) echo "Skipping..."
          true
        ;;
        * )
          echo "Invalid input: '$response'. Skipping..."
        ;;
      esac

      echo "Unmounting..."
      sudo umount -R -l /media/sd

      echo "Done!"
    ''
  };
}
