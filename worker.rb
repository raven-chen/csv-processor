require 'smarter_csv'
require 'string-urlize'
require 'csv'
require 'pry'

class Worker
    def load_csvs
        pim_data = CSV.read("./pim_ot2017-6-14.csv")

        cn_products = CSV.read("./products-cn.csv")
        # jp_products = CSV.read("./products-jp.csv")
        # kr_products = CSV.read("./products-kr.csv")
        # tw_products = CSV.read("./products-tw.csv")

    end

    def generate_csv country_code, locale
        p "Generating csv for #{locale}, #{country_code}"
        products = SmarterCSV.process("./products-#{country_code}.csv")

        header = ["URL Title (OT 2)", "Name", "Code", "Color Code", "Global ID", "URL Title (OT 3 DEV)"]
        CSV.open("./results/#{country_code}.csv", "wb") do |csv|
            csv << header

            products.each do |product|
                color_code = product[:color_code].match(/\d+/)[0]
                article_code = product[:article_code].downcase
                cor_product = get_corresponding_product article_code,color_code, locale
                if cor_product
                    name_in_url = CGI.escape(product[:article_name].urlize(:transliterate => false))
                    ot2_url = gen_ot2_url locale, name_in_url, article_code, color_code
                    ot3_url = gen_ot3_url country_code, locale, name_in_url, cor_product[:globalid], color_code
                    csv << [ot2_url, product[:article_name], article_code, color_code, cor_product[:globalid], ot3_url]
                end
            end
        end
    end

    def get_corresponding_product style_number, color_code, locale
        @pim_data ||= SmarterCSV.process("./pim_ot2017-6-14.csv")
        result = nil

        @pim_data.each do |data|
            if data[:stylenumber] == style_number && data[:colorcode] == color_code.to_i && locale == data[:language_code]
                result = data
                binding.pry
                break;
            end
        end

        return result
    end

    def gen_ot2_url locale, name, article_code, color_code
        "http://www.onitsukatiger.com/#{locale}#!product/#{name}-#{article_code}-#{color_code}"
    end

    def gen_ot3_url country_code, locale, name, global_id, color_code
        "https://ot3.theplant-dev.com/#{country_code}/#{locale}/#{name}/p/#{global_id}-#{color_code}"
    end
end

a = Worker.new
a.generate_csv ENV["C_CODE"], ENV["LOCALE"]
