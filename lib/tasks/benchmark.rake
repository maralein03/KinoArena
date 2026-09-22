require "net/http"

# NFA-3: belegt, dass die Spielplanuebersicht unter gleichzeitiger Last schnell genug bleibt.
namespace :benchmark do
  desc "Misst die Antwortzeit des Spielplans unter gleichzeitiger Last (NFA-3)"
  task :showtimes do
    url = URI.parse(ENV.fetch("URL", "http://localhost:3000/"))
    requests = ENV.fetch("REQUESTS", 50).to_i
    concurrency = ENV.fetch("CONCURRENCY", requests).to_i
    limit = ENV.fetch("LIMIT", 1.5).to_f

    puts "NFA-3 Lasttest"
    puts "  Ziel:            #{url}"
    puts "  Anfragen:        #{requests} (#{concurrency} gleichzeitig)"
    puts "  Grenzwert:       #{limit} s pro Anfrage"
    puts

    begin
      Net::HTTP.get_response(url)
    rescue SystemCallError => e
      abort "  Server nicht erreichbar (#{e.message}). Starte ihn mit: bin/dev"
    end

    # Aufwaermen: der erste Zugriff pro Thread laedt Code und fuellt Caches.
    Array.new(concurrency) { Thread.new { Net::HTTP.get_response(url) } }.each(&:join)

    durations = []
    statuses = []
    mutex = Mutex.new
    queue = Queue.new
    requests.times { queue << true }

    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    Array.new(concurrency) do
      Thread.new do
        Net::HTTP.start(url.host, url.port) do |http|
          while queue.pop(true)
            started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            response = http.get(url.path.presence || "/")
            elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

            mutex.synchronize do
              durations << elapsed
              statuses << response.code
            end
          end
        rescue ThreadError
          # Queue leer: dieser Thread ist fertig
        end
      end
    end.each(&:join)

    wall_clock = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

    sorted = durations.sort
    percentile = ->(p) { sorted[[ (sorted.size * p).ceil - 1, 0 ].max] }

    puts "  Gesamtdauer:     #{format('%.3f', wall_clock)} s"
    puts "  Durchsatz:       #{format('%.1f', requests / wall_clock)} Anfragen/s"
    puts
    puts "  Schnellste:      #{format('%.3f', sorted.first)} s"
    puts "  Median (p50):    #{format('%.3f', percentile.call(0.50))} s"
    puts "  p95:             #{format('%.3f', percentile.call(0.95))} s"
    puts "  Langsamste:      #{format('%.3f', sorted.last)} s"
    puts "  HTTP-Status:     #{statuses.tally.map { |code, count| "#{code} x#{count}" }.join(', ')}"
    puts

    if statuses.uniq != [ "200" ]
      abort "  FEHLGESCHLAGEN: nicht alle Anfragen lieferten HTTP 200."
    elsif sorted.last <= limit
      puts "  BESTANDEN: auch die langsamste Anfrage blieb unter #{limit} s."
    else
      abort "  FEHLGESCHLAGEN: langsamste Anfrage #{format('%.3f', sorted.last)} s > #{limit} s."
    end
  end
end
