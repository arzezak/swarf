# frozen_string_literal: true

module SwarfHelpers
  private

  def ruby(*args, chdir:, swarf_dir:)
    IO.popen([{"SWARF_DIR" => swarf_dir}, RbConfig.ruby, "-I#{LIB}", *args],
      chdir: chdir, err: %i[child out], &:read)
  end

  def write_file(path, body)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, body)
  end

  def measurement_of(path, lines: [], branches: {}, methods: {})
    Swarf::Measurement.new(path, {"sha" => Digest::SHA256.file(path).hexdigest,
                                  "lines" => lines, "branches" => branches, "methods" => methods})
  end

  def stored_coverage(dir)
    JSON.parse(File.read(File.join(dir, ".swarf", Swarf::Store::FILENAME)))
  end
end
