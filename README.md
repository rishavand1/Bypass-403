How to Use (Step-by-Step)

chmod +x bypass_403.sh

Run dirsearch first (if you haven't)Bashdirsearch -u https://url.com -e * --output dirsearch_results.txt

Run the bypass scriptBash./bypass_403.sh -u https://url.com -e dirsearch_results.txt


<img width="797" height="572" alt="403-1" src="https://github.com/user-attachments/assets/0e700ae9-e124-4846-b9b6-aa2c8323a2dd" />

Optional flags

-t 15 → set timeout to 15 seconds (default = 10)

Example with custom timeout:Bash./bypass_403.sh -u https://url.com -e dirsearch_results.txt -t 20


<img width="1016" height="463" alt="403-2" src="https://github.com/user-attachments/assets/2c3d7f44-b36a-45b0-9c85-33a9bbb20842" />


The script tries all major bypass methods (HTTP methods, headers, path tricks, encodings, combinations). It stops at the first successful bypass per endpoint to save time, but you can remove the break line if you want every technique tested.
