require "minitest/autorun"
require "minitest/pride"

#load relatives from current dir
$LOAD_PATH << "."
require "build_dsl_attempt"

class DocumentDslTest < Minitest::Test
  include DocumentDsl

  def test_assemble_empty_doc
    integration_type = { name: "API", deprecated: false }

    document = document(author: "test-author", name: "test-name") do |children|
      children << application(name: "app-name", spi: "SP-SP") do |app_child|
        app_child << service(name: "service-name", integration_type: integration_type) do |service_child|
          service_child << structure(name: "ABC", type: "SQL")
          service_child << structure(name: "ABC", type: "SQL")
        end
      end
    end

    assert_equal document, {
      family: "flow", author: "test-author", name: "test-name",
      applications: [
        {
          name: "app-name", spi: "SP-SP",
          services: [
            {
              name: "service-name", integration_type: integration_type,
              structures: [
                { name: "ABC", type: "SQL" },
                { name: "ABC", type: "SQL" },
              ],
            },
          ],
        },
      ],
    }
  end
end
