chiafactory-simple-download
===========================

This is a simple script to download your chia plots from chiafactory.com and move them to your target destination. 

It is single-threaded, but simple.

It will only download the first undownloaded plot from the first active plot_order. It continues to do this in a loop.

Using
=====

Set the following variables in start.sh

```
DOWNLOAD_DIR=***  # Path to any download directory where files will be downloaded
FINAL_DIR=***     # Path to final chiafarm plot directory where chia will pick it up.
```

Note: It is quicker if DOWNLOAD_DIR and FINAL_DIR is on the same disk/partition. Then moving will only relink the file in the directory tree and not have to move such a large file.

```
    export PLOTORDER_API_KEY=xxxxx   # Acquire a PLOTORDER_API_KEY on the website if available, or by contacting support
    ./start.sh <order_id>
```

Disclaimer
==========

Use at own risk. Deleting the plot is not currently tested
