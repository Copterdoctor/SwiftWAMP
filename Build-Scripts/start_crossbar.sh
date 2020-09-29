/usr/local/bin/docker run -v  ~/SwiftWAMP:/node -u 0 --rm --name=crossbar -d -p 8080:8080 crossbario/crossbar
# Give router time to initialise before trying to use it.
# Adjust this accordingly to your computers behaivour
sleep 10
# run in interactive mode
# /usr/local/bin/docker run -v  ~/SwiftWAMP:/node -u 0 --rm --name=crossbar -it -p 8080:8080 crossbario/crossbar
