require "zip"

module Services
  module System
  class BulkDocumentExporter
    def self.export(documentable)
      documents = documentable.documents.includes(file_attachment: :blob)
      return nil if documents.empty?

      temp_file = Tempfile.new([ "documents_export", ".zip" ])

      Zip::OutputStream.open(temp_file.path) do |zos|
        documents.each do |doc|
          next unless doc.file.attached?

          zos.put_next_entry(doc.file.filename.to_s)
          zos.write(doc.file.download)
        end
      end

      temp_file
    end
  end
end
end