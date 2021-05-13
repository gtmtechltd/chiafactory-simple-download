chiafactory-simple-download
===========================

**new** - now multithreaded - up to 3 concurrent download threads

It will only download the first undownloaded plot from the first active plot_order. It continues to do this in a loop.


Disclaimer
==========

** !! Use at own risk. !!  **- By using these scripts you agree that you are responsible for any outcomes caused by the using of these scripts. In this respect full source code is viewable by you and it is intended that you review the source code before running to ensure you are happy with what it does.

The highest risk area of these scripts are to auto-mark plots on chiafactory as deleted when finished downloading successfully,- as a result, you will then not have access to them. This is necessary so that more download slots are freed up. Every effort was taken to ensure that should errors occur, the plots will not be marked for deletion, but if there are bugs in this logic, unintended deleted plots could occur. You must check out the logic in `spawn-download.sh` before running and make sure you are happy with what it does. 

This is a simple script to download your chia plots from chiafactory.com and move them to your target destination. 

Setup
=====

* You will need a plotorder api key. You can get one of these by contacting support.
* You need jq, wget and curl installed:

```
        sudo apt install jq wget curl
or:     sudo yum install jq wget curl
or:     brew install jq wget curl
```

Using
=====

Copy `config.json.example` to `config.json` and configure it:

```
{
  "download_dir":             "***",    # Path to any download directory where files will be downloaded
  "final_dir":                "***",    # Path to final chiafarm plot directory where chia will pick it up.
  "max_concurrent_downloads": 2         # How many downloads to perform at once, bearing in mind increasing may not make it faster if network IO is your limiting factor
  "plotorder_api_key":        "***",    # Acquire a plotorder API key on the website if available, or by contacting support
}
```

Note: It is quicker if `download_dir` and `final_dir` are on the same disk/partition. Then moving will only relink the file in the directory tree and not have to move such a large file.

```
    ./start.sh
```


