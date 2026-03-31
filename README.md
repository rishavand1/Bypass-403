How to Use (Step-by-Step)

Save the scriptBashnano bypass_403.sh
# Paste the code above → Ctrl+X → Y → Enter
chmod +x bypass_403.sh
Run dirsearch first (if you haven't)Bashdirsearch -u https://techport.nasa.gov -e * --output dirsearch_results.txt
Run the bypass scriptBash./bypass_403.sh -u https://techport.nasa.gov -e dirsearch_results.txt
Optional flags
-t 15 → set timeout to 15 seconds (default = 10)
Example with custom timeout:Bash./bypass_403.sh -u https://techport.nasa.gov -e dirsearch_results.txt -t 20


The script tries all major bypass methods (HTTP methods, headers, path tricks, encodings, combinations). It stops at the first successful bypass per endpoint to save time, but you can remove the break line if you want every technique tested.
