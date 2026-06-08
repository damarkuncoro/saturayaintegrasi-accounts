namespace :standards do
  desc "Explore BPS standardizations via CLI"
  task :explore, [ :query ] => :environment do |t, args|
    query = args[:query]
    if query.blank?
      puts "Usage: rails standards:explore[keyword]"
      next
    end

    puts "\n🔎 Searching for '#{query}' in all BPS Standards...\n\n"

    # Search KBJI
    kbji_results = Taxonomy::KbjiRole.search_by_query(query).latest.limit(10)
    print_results("KBJI (Pekerjaan)", kbji_results)

    # Search KBLI
    kbli_results = Taxonomy::KbliSector.search_by_query(query).latest.limit(10)
    print_results("KBLI (Industri)", kbli_results)

    # Search KBKI
    kbki_results = Taxonomy::KbkiCommodity.search_by_query(query).latest.limit(10)
    print_results("KBKI (Komoditas)", kbki_results)
  end

  def print_results(title, results)
    puts "=== #{title} ==="
    if results.empty?
      puts "No results found."
    else
      printf("%-10s | %-40s | %-6s | %-10s\n", "Kode", "Judul", "Versi", "Info")
      puts "-" * 75
      results.each do |r|
        info = case r
        when Taxonomy::KbliSector then "Level #{r.level}"
        when Taxonomy::KbkiCommodity then r.commodity_type.capitalize
        else "-"
        end
        printf("%-10s | %-40s | %-6s | %-10s\n", r.code, r.title.truncate(38), r.version, info)
      end
    end
    puts "\n"
  end
end
