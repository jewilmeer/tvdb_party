module TvdbParty
  class Search
    include HTTParty
    include HTTParty::Icebox
    attr_accessor :language
    cache #:store => 'file', :timeout => 120, :location => Dir.tmpdir + '/tvdb_party'

    base_uri 'www.thetvdb.com/api'

    def initialize(the_api_key, language = 'en')
      @api_key = the_api_key
      @language = language
    end

    def search(series_name)
      response = self.class.get("/GetSeries.php", {:query => {:seriesname => series_name, :language => @language}}).parsed_response
      return [] unless response["Data"]

      case response["Data"]["Series"]
      when Array
        response["Data"]["Series"]
      when Hash
        [response["Data"]["Series"]]
      else
        []
      end
    end

    def get_series_updates(timestamp)
      response = self.class.get("/Updates.php", {:query => { :time => timestamp, :type => 'series'}}).parsed_response
      return response["Items"] ? response["Items"] : []
    end

    def get_episodes_updates(timestamp)
      response = self.class.get("/Updates.php", {:query => { :time => timestamp, :type => 'episode'}}).parsed_response
      return response["Items"] ? response["Items"] : []
    end

    def get_all_updates(timestamp)
      response = self.class.get("/Updates.php", {:query => { :time => timestamp, :type => 'all'}}).parsed_response
      return response["Items"] ? response["Items"] : []
    end

    def get_series_by_id(series_id, language = self.language)
      response = self.class.get("/#{@api_key}/series/#{series_id}/#{language}.xml").parsed_response

      if response["Data"] && response["Data"]["Series"]
        Series.new(self, response["Data"]["Series"])
      else
        nil
      end
    end

    def get_episode_by_id(episode_id, language = self.language)
      response = self.class.get("/#{@api_key}/episodes/#{episode_id}/#{language}.xml").parsed_response
      if response["Data"] && response["Data"]["Episode"]
        Episode.new(response["Data"]["Episode"])
      else
        nil
      end
    end

    def get_episode(series, season_number, episode_number, language = self.language)
      response = self.class.get("/#{@api_key}/series/#{series.id}/default/#{season_number}/#{episode_number}/#{language}.xml").parsed_response
      if response["Data"] && response["Data"]["Episode"]
        Episode.new(response["Data"]["Episode"])
      else
        nil
      end
    end

    def get_all_episodes_by_id(serie_id, language = self.language)
      response = self.class.get("/#{@api_key}/series/#{serie_id}/all/#{language}.xml").parsed_response
      return [] unless response["Data"] && response["Data"]["Episode"]
      case response["Data"]["Episode"]
      when Array
        response["Data"]["Episode"].map{|result| Episode.new(result)}
      when Hash
        [Episode.new(response["Data"]["Episode"])]
      else
        []
      end
    end

    def get_all_episodes(series, language = self.language)
      get_all_episodes_by_id series.id, language
    end

    def get_actors_by_id(serie_id)
      response = self.class.get("/#{@api_key}/series/#{serie_id}/actors.xml").parsed_response
      if response["Actors"] && response["Actors"]["Actor"]
        response["Actors"]["Actor"].collect {|a| Actor.new(a)}
      else
        nil
      end
    end

    def get_actors(series)
      get_actors_by_id series.id
    end

    def get_banners_by_id serie_id
      response = self.class.get("/#{@api_key}/series/#{serie_id}/banners.xml").parsed_response
      return [] unless response["Banners"] && response["Banners"]["Banner"]
      case response["Banners"]["Banner"]
      when Array
        response["Banners"]["Banner"].map{|result| Banner.new(result)}
      when Hash
        [Banner.new(response["Banners"]["Banner"])]
      else
        []
      end
    end

    def get_banners(series)
      get_banners_by_id series.id
    end

  end
end