# frozen_string_literal: true

module Core
  class BaseRepository
    include Normalizable

    # Mencari record berdasarkan ID dan mengembalikannya sebagai entity.
    # @param id [Integer, String] ID record
    # @return [Object, nil] Entity atau nil jika tidak ditemukan
    def find(id)
      record = model_class.find_by(id: id)
      return nil unless record
      to_entity(record)
    end

    # Mengambil semua record dan mengembalikannya sebagai array of entities.
    # @return [Array<Object>]
    def all
      model_class.all.map { |record| to_entity(record) }
    end

    # Menyimpan record baru ke database.
    # @param attributes [Hash] Atribut record
    # @return [Object] Entity
    def create(attributes)
      record = model_class.create!(attributes)
      to_entity(record)
    end

    # Memperbarui record yang ada.
    # @param id [Integer, String] ID record
    # @param attributes [Hash] Atribut yang diupdate
    # @return [Object] Entity
    def update(id, attributes)
      record = model_class.find(id)
      record.update!(attributes)
      to_entity(record)
    end

    # Menghapus record (atau soft-delete jika didukung).
    # @param id [Integer, String] ID record
    # @return [Boolean]
    def delete(id)
      record = model_class.find(id)
      if record.respond_to?(:discard)
        record.discard
      else
        record.destroy
      end
    end

    # Melakukan pagination pada query.
    # @param scope [ActiveRecord::Relation] Scope awal (default: model_class)
    # @param page [Integer] Nomor halaman
    # @param per_page [Integer] Jumlah item per halaman
    # @return [Hash] Berisi data entities dan metadata pagination
    def paginate(scope = nil, page: 1, per_page: 20)
      scope ||= model_class
      
      # Menggunakan Pagy jika tersedia, jika tidak gunakan Kaminari/WillPaginate style
      if defined?(::Pagy) && ::Pagy.respond_to?(:root)
        pagy, records = ::Pagy.new(count: scope.count, page: page, items: per_page).then do |p|
          [p, scope.offset(p.offset).limit(p.items)]
        end
        
        {
          data: records.map { |record| to_entity(record) },
          meta: {
            current_page: pagy.page,
            total_pages: pagy.pages,
            total_count: pagy.count,
            per_page: per_page
          }
        }
      elsif scope.respond_to?(:page)
        paginated = scope.page(page).per(per_page)
        {
          data: paginated.map { |record| to_entity(record) },
          meta: {
            current_page: paginated.current_page,
            total_pages: paginated.total_pages,
            total_count: paginated.total_count,
            per_page: per_page
          }
        }
      else
        # Fallback manual jika tidak ada gem pagination
        offset = (page.to_i - 1) * per_page.to_i
        records = scope.offset(offset).limit(per_page)
        total_count = scope.count
        
        {
          data: records.map { |record| to_entity(record) },
          meta: {
            current_page: page.to_i,
            total_pages: (total_count.to_f / per_page).ceil,
            total_count: total_count,
            per_page: per_page
          }
        }
      end
    end

    protected

    # Harus diimplementasikan oleh subclass untuk menentukan model ActiveRecord yang digunakan.
    # @return [Class]
    def model_class
      raise NotImplementedError, "#{self.class} harus mengimplementasikan method #model_class"
    end

    # Harus diimplementasikan oleh subclass untuk memetakan record ke entity.
    # @param record [ActiveRecord::Base]
    # @return [Object] Entity
    def to_entity(record)
      raise NotImplementedError, "#{self.class} harus mengimplementasikan method #to_entity"
    end
  end
end
