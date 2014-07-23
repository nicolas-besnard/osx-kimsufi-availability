rm ks_original
wget http://www.kimsufi.com/fr/index.xml -O ks_original -q

while :
do
    now=$(date +"%T")
    wget http://www.kimsufi.com/fr/index.xml -O ks_new -q
    if cmp -s ks_original ks_new; then
	echo "[$now] No New Server :("
    else
 	terminal-notifier -title 'Kimsufi' -message 'New Server Available' -open 'https://www.kimsufi.com/fr/index.xml'
	echo "[$now] !!! NEW SERVER !!!"
	mv ks_new ks_original
    fi
    rm ks_new
    sleep 10
done