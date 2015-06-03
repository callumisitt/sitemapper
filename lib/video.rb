class Video
  require 'httparty'
  
  def initialize(url, root_url)
    @url = url
    @root_url = root_url
  end
  
  def get_vimeo_info(url, page_url)
    video = HTTParty.get("https://vimeo.com/api/oembed.json?url=https%3A//vimeo.com/#{url}")
    {
      video_thumbnail_location: video['thumbnail_url'],
      video_title: video['title'],
      video_description: video['description'],
      video_player_location: "#{@root_url}#{page_url}",
      video_duration: video['duration']
    }
  end

  def get_youtube_info(url, page_url)
    video = HTTParty.get("https://www.googleapis.com/youtube/v3/videos?part=snippet&key=AIzaSyCbxrNpIW-yzXuXtK_yzpwGpaejprYzRMY&id=#{url}")
    video = video['items'][0]['snippet']
    {
      video_thumbnail_location: video['thumbnails']['default']['url'],
      video_title: video['title'],
      video_description: video['description'],
      video_player_location: "#{@root_url}#{page_url}"
    }
  end

  def video_host(video)
    video[0].include?('vimeo') ? 'vimeo' : 'youtube'
  end

  def details
    return {} if @url == @root_url
    page = HTTParty.get("#{@root_url}#{@url}")
    video = page.match(/(player.vimeo.com\/video|youtube.com\/embed)\/([^"\?]*)/)
    return {} unless video
    puts "Adding video #{video[2]}"
    self.send("get_#{video_host(video)}_info", video[2], @url)
  end
end