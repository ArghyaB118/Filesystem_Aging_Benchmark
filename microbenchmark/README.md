# microbenchmarks
1. randomlinuxtest.py / rltresultify.py
  1. first do git clone https://github.com/torvalds/linux.git in this dir
  2. then rm -rf linux/.git
  3. edit fs_scripts/fs-info.sh
  4. edit agedmntpnt/agedblkdevice in randomlinuxtest.py
  5. sudo python randomlinuxtest.py -- note it prints the results, it doesn't save them
  6. sudo python rltresultify.py -- note it prints the results, it doesn't save them
2. rrtest.py / rrresultify.py
  1. edit fs_scripts/fs-info.sh and clean_fs_scripts/fs-info.sh
  2. edit agedmntpnt/agedblkdevice/cleanmmntpnt/cleanblkdevice in rrtest.py
  3. sudo python rrtest.py
  4. sudo python rrresultify.py
  5. results are in rr.csv
3. smallfiletest.py / sfresultify.py
  1. edit fs_scripts/fs-info.sh and clean_fs_scripts/fs-info.sh
  2. edit agedmntpnt/agedblkdevice/cleanmmntpnt/cleanblkdevice in smallfiletest.py
  3. sudo python smallfiletest.py
  4. sudo python sfresultify.py
  5. results are in sfresults.csv (not sf_results.csv sorry)
