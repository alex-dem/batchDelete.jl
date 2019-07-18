using Distributed

# set the number of workers (even number)
nWorkers = 4

# turn on the debugmode (no actual deletion)
debugMode = true

# define the path where all the files are located that need deletion
targetDir = "/tmp/test"

if nWorkers < 2
    error("Please use a number of workers greater than 2")
end

# set up nWorkers
rmprocs()
addprocs(nWorkers)

# read the files from a directory
listFiles = readdir(targetDir)

# determine the total number of files
nFiles = length(listFiles)

# determine the number of files per worker
pWorker = convert(Int, ceil(nFiles / nWorkers))-1

if debugMode
    @info "There are $nFiles files to be deleted using $nWorkers workers. Every worker deletes $pWorker files."
end

# launch the system commands
@sync for (p, pid) in enumerate(workers())
    @async @spawnat (p + 1) begin

        # determine the index in the file vector per worker
        startMarker = (p - 1) * pWorker + 1
        endMarker   = p * pWorker

        if debugMode
            @info "running the files from $startMarker to $endMarker"
        end

        for k=startMarker:endMarker
            if debugMode
                @info "worker $pid: remove file at position $k: $(listFiles[k])"
            else
                run(`rm -rf $targetDir/$(listFiles[k])`)
            end
        end
    end
end

# remove the last file separately if an odd list
for k = (pWorker * nWorkers + 1):nFiles
    if debugMode
        @info "removing file $k in the stack"
    else
        run(`rm -rf $targetDir/$(listFiles[end])`)
    end
end
