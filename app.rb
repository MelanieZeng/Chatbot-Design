require 'sinatra'
require 'sinatra/reloader' if development?
require 'twilio-ruby'
require 'net/http'
require 'json'

configure :development do
  require 'dotenv'
  Dotenv.load
end

enable :sessions

#glocal variables
greetings = ["Hi there,", "Hello,", "Hi,", "How are you?", "How's it going?", "Hey!", "What's up!"]
greetings_mn = ["Good morning!", "Morning!"]
greetings_an = ["Good afternoon!"]
greetings_en = ["Good evening!", "Evening!"]
secret_code = "melanieiscool"

get '/' do 
	session["visits"] ||= 0
	session["visits"] = session["visits"] + 1 
	time = Time.now
	if session[:first_name].nil?
		"Imagine you are sitting in a nice bar and wondering what drink you should get. Your bartender made you a perfect cocktail for the night. Wouldn't it be nice?! Sign up to chat with me now! <br />Total visits on our website: " + session["visits"].to_s
    else 
    	if session["visits"] > 10 #make a user a VIP after they visit the website more than 10 times
    		session[:first_name] + ', You are a VIP now!' + '<br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
    	else #show different greetings based on the time during a day
			if time.hour >= 5 and time.hour <= 14
				greetings_mn.sample + ', ' + session[:first_name] + '. <br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
			elsif time.hour > 14 and time.hour <= 18
				greetings_an.sample + ', ' + session[:first_name] + '. <br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
			else
				greetings_en.sample + ', ' + session[:first_name] + '. <br /> You have visited ' + session["visits"].to_s + ' times as of ' + time.strftime("%A %B %d, %Y %H:%M")
			end
		end
	end
end

#modify signup page
get '/signup' do
	if params[:code] == secret_code
		erb :signup
	else
		404
	end
end

post '/signup' do
	#code to check parameters
	client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]
	if params[:code] == secret_code
		if params[:first_name] == '' or params[:number] == ''
			'Please sign up with your first name and number.'
		else
			session[:first_name] = params[:first_name]
			session[:number] = params[:number]
			# this will send a message from any end point
			client.api.account.messages.create(
				from: ENV["TWILIO_FROM"],
				to: params[:number],
				body: 'Hi ' + session[:first_name] + ', you are all set!'
				)
			greetings.sample + ' ' + session[:first_name] + '. You will receive a confirmation message from me in a few minutes.'
		end
	end
end

#get url of incoming image
# get '/image/test' do
	
# # 	# num_media = params['NumMedia'].to_i

# # 	# if num_media > 0
# # 	# 	for i in 0..(num_media - 1) do
# # 	# 		media_url = params["MediaUrl#{i}"]
# # 	# 	end
# # 	# end

# 	# Pull facial recoginition data from Microsoft Azure
# 	# You must use the same location in your REST call as you used to get your
# 	# subscription keys. For example, if you got your subscription keys from  westus,
# 	# replace "westcentralus" in the URL below with "westus".
# 	uri = URI('https://westcentralus.api.cognitive.microsoft.com/face/v1.0/detect')
# 	uri.query = URI.encode_www_form({
# 	    # Request parameters
# 	    'returnFaceId' => 'true',
# 	    'returnFaceLandmarks' => 'false',
# 	    'returnFaceAttributes' => 'age,gender,headPose,smile,facialHair,glasses,' +
# 	        'emotion,hair,makeup,occlusion,accessories,blur,exposure,noise'
# 	})

# 	request = Net::HTTP::Post.new(uri.request_uri)

# 	# Request headers
# 	# Replace <Subscription Key> with your valid subscription key.
# 	request['Ocp-Apim-Subscription-Key'] = ENV['key_1']
# 	request['Content-Type'] = 'application/json'

# 	imageUri = "https://www.yourtango.com/sites/default/files/styles/body_image_default/public/image_list/smile_0.jpg?itok=T_VpgMvQ"
# 	request.body = "{\"url\": \"" + imageUri + "\"}"

# 	response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
# 	    http.request(request)
# 	end

# 	#pull the data I need
# 	data = JSON.parse(response.body)
# 	face_attributes = data[0]["faceAttributes"]
# 	age = face_attributes["age"].to_i
# 	emotion_set = face_attributes["emotion"]
# 	emotion_set_max_value_map = emotion_set.select {|k,v| v == emotion_set.values.max } #It's a dictionary
# 	emotion_keys = emotion_set_max_value_map.keys #It's an array
# 	emotion = emotion_keys[0] #Take the first string

# 	if age < 16
# 		uri = URI ("https://www.thecocktaildb.com/api/json/v1/1/filter.php?a=Non_Alcoholic")
# 		response = Net::HTTP.get(uri)
# 		drink_dicionary = JSON.parse(response)
# 		drink_array = drink_dicionary["drinks"]
# 		drink = drink_array.sample
# 		message = "You seem too young to try alcoholic drinks! How about trying " + drink["strDrink"] + "?"
# 		media = drink["strDrinkThumb"]

# 	elsif age >= 16
# 		if emotion == "anger"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Coffee%20/%20Tea")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Chill bro! Try some " + drink["strDrink"] + ". "
# 			media = drink["strDrinkThumb"]
# 		elsif emotion == "contempt"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Homemade%20Liqueur")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Don't judge the " + drink["strDrink"] + ". "
# 			media = drink["strDrinkThumb"]
# 		elsif emotion == "disgust"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Shot")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Take this " + drink["strDrink"] + "shot and don't stop! "
# 			media = drink["strDrinkThumb"]
# 		elsif emotion == "fear"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Cocoa")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Are you ok? I think you need some " + drink["strDrink"]
# 			media = drink["strDrinkThumb"]
# 		elsif emotion == "happiness"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Punch%20/%20Party%20Drink")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Let's partyyy! Get some " + drink["strDrink"]
# 			media = drink["strDrinkThumb"]
# 		elsif emotion == "neutral"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Cocktail")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Yo I got you some " + drink["strDrink"]
# 			media = drink["strDrinkThumb"]
# 		elsif emotion == "sadness"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Beer")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Aww you look so sad! Try some " + drink["strDrink"]
# 			media = drink["strDrinkThumb"]
# 		elsif emotion == "surprise"
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Ordinary_Drink")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "You look surprised! How about a " + drink["strDrink"]
# 			media = drink["strDrinkThumb"]
# 		else
# 			uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Milk%20/%20Float%20/%20Shake")
# 			response = Net::HTTP.get(uri)
# 			drink_dicionary = JSON.parse(response)
# 			drink_array = drink_dicionary["drinks"]
# 			drink = drink_array.sample
# 			message = "Hey, try some " + drink["strDrink"]
# 			media = drink["strDrinkThumb"]
# 		end
# 	else
# 		uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Other/Unknown")
# 		response = Net::HTTP.get(uri)
# 		drink_dicionary = JSON.parse(response)
# 		drink_array = drink_dicionary["drinks"]
# 		drink = drink_array.sample
# 		message = "Would you like some " + drink["strDrink"]
# 		media = drink["strDrinkThumb"]
# 	end
    
#     puts age, emotion, message, media

# end

#modify incoming/sms page
post '/incoming/sms' do
	session["counter"] ||= 1
	time = Time.now
	media_url = params["MediaUrl"]
	body = params[:Body] || ""

	# Pull facial recoginition data from Microsoft Azure
    uri = URI('https://westcentralus.api.cognitive.microsoft.com/face/v1.0/detect')
	uri.query = URI.encode_www_form({
	    # Request parameters
	    'returnFaceId' => 'true',
	    'returnFaceLandmarks' => 'false',
	    'returnFaceAttributes' => 'age,gender,headPose,smile,facialHair,glasses,' +
	        'emotion,hair,makeup,occlusion,accessories,blur,exposure,noise'
	})

	request = Net::HTTP::Post.new(uri.request_uri)

	# Request headers
	# Replace <Subscription Key> with your valid subscription key.
	request['Ocp-Apim-Subscription-Key'] = ENV['key_1']
	request['Content-Type'] = 'application/json'

	imageUri = media_url
	request.body = "{\"url\": \"" + imageUri + "\"}"

	response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
	    http.request(request)
	end

	#pull the data I need
	data = JSON.parse(response.body)
	face_attributes = data[0]["faceAttributes"]
	age = face_attributes["age"].to_i
	emotion_set = face_attributes["emotion"]
	emotion_set_max_value_map = emotion_set.select {|k,v| v == emotion_set.values.max } #It's a dictionary
	emotion_keys = emotion_set_max_value_map.keys #It's an array
	emotion = emotion_keys[0] #Take the first string

	if session["counter"] == 1
		#greeting based on different time of a day
		if time.hour >= 5 and time.hour <= 12
    		message = greetings_mn.sample + " Great to hear your first message! I am Moscow Muler🍸. Would you like to pick your morning drink? Send me a seflie that best describes your mood now! "
			media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
		elsif time.hour > 12 and time.hour <= 18
			message = greetings_an.sample + " Great to hear your first message! I am Moscow Muler🍸. Would you like to pick your afternoon drink? Send me a seflie that best describes your mood now! "
			media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
		else
			message = greetings_en.sample + " Great to hear your first message! I am Moscow Muler🍸. Are you ready to partyyy? Show me your ready-party selfie and let me pick a drink for ya! "
			media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
		end
    else
    	if media_url.nil?
    		message = determine_response body
    	else
			if age < 16
				uri = URI ("https://www.thecocktaildb.com/api/json/v1/1/filter.php?a=Non_Alcoholic")
				response = Net::HTTP.get(uri)
				drink_dicionary = JSON.parse(response)
				drink_array = drink_dicionary["drinks"]
				drink = drink_array.sample
				message = "You seem too young to try alcoholic drinks! How about trying " + drink["strDrink"] + "?"
				media = drink["strDrinkThumb"]

			elsif age >= 16
				if emotion == "anger"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Coffee%20/%20Tea")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Chill bro! Try some " + drink["strDrink"] + ". "
					media = drink["strDrinkThumb"]
				elsif emotion == "contempt"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Homemade%20Liqueur")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Don't judge the " + drink["strDrink"] + ". "
					media = drink["strDrinkThumb"]
				elsif emotion == "disgust"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Shot")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Take this " + drink["strDrink"] + "shot and don't stop! "
					media = drink["strDrinkThumb"]
				elsif emotion == "fear"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Cocoa")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Are you ok? I think you need some " + drink["strDrink"] + ". "
					media = drink["strDrinkThumb"]
				elsif emotion == "happiness"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Punch%20/%20Party%20Drink")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Let's partyyy! Get some " + drink["strDrink"] + "! "
					media = drink["strDrinkThumb"]
				elsif emotion == "neutral"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Cocktail")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Yo I got you some " + drink["strDrink"] + "! "
					media = drink["strDrinkThumb"]
				elsif emotion == "sadness"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Beer")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Aww you look so sad! Try some " + drink["strDrink"] + ". "
					media = drink["strDrinkThumb"]
				elsif emotion == "surprise"
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Ordinary_Drink")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "You look surprised! How about a " + drink["strDrink"] + "? "
					media = drink["strDrinkThumb"]
				else
					uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Milk%20/%20Float%20/%20Shake")
					response = Net::HTTP.get(uri)
					drink_dicionary = JSON.parse(response)
					drink_array = drink_dicionary["drinks"]
					drink = drink_array.sample
					message = "Hey, try some " + drink["strDrink"] + ". "
					media = drink["strDrinkThumb"]
				end
			else
				uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Other/Unknown")
				response = Net::HTTP.get(uri)
				drink_dicionary = JSON.parse(response)
				drink_array = drink_dicionary["drinks"]
				drink = drink_array.sample
				message = "Would you like some " + drink["strDrink"] + "? "
				media = drink["strDrinkThumb"]
			end
		end
	end


	# Build a twilio response object 
	twiml = Twilio::TwiML::MessagingResponse.new do |r|
		r.message do |m|

		# add the text of the response
	    	m.body ( message )
				
			# add media if it is defined
	    	unless media.nil?
	    		m.media( media )
	    	end
	    end
    end

    # increment the session counter
    session["counter"] += 1

    # send a response to twilio 
    content_type 'text/xml'
    twiml.to_s
end

#error 404
error 404 do
	"Access Forbidden"
end

#methods
def determine_response body
	body = body.downcase.strip
	hi_vocabs = ["hi", "hello", "hey"]
	what_vocabs = ["what", "help", "feature", "function", "guide"]
	who_vocabs = ["who"]
	where_vocabs = ["where", "location", "city"]
	when_vocabs = ["when", "created", "born", "made"]
	why_vocabs = ["why", "purpose", "for", "meaning"]
	joke_vocabs = ["joke", "jokes", "bored", "fun"]
	yes_vocabs = ["yes", "yeah", "yup", "sure", "sounds good", "ok", "I'd love to"]

	if has_vocab_in_sentence body, hi_vocabs
		'Hey, I am Moscow Muler 🍸! I am your bartender tonight! Show me your ready-party look and I will pick the perfect drink for ya! '
	elsif has_vocab_in_sentence body, who_vocabs
		'I am a MeBot of Melanie Zeng. Reply "fact" to know more about Melanie! '
	elsif has_vocab_in_sentence body, what_vocabs
		'I can pick the perfect cocktail based on your mood for you or a get-her/get-him drink for your girl/man tonight! 😉'
	elsif has_vocab_in_sentence body, where_vocabs
		'I live in Pittsburgh! '
	elsif has_vocab_in_sentence body, when_vocabs
		'I was created in Fall 2018! '
	elsif has_vocab_in_sentence body, why_vocabs
		'I was made by Melanie Zeng for her Programming for Online Prototypes Class! '
	elsif has_vocab_in_sentence body, joke_vocabs
		file = File.open("jokes.txt", "r")
		array_of_lines = IO.readlines("jokes.txt")
		return array_of_lines.sample + "\n Reply 'Joke was good' if you like it or 'Joke was bad' if you don't. Don't be mean to me please!"
	elsif body.include? 'Joke was good'
		'Thank you for the complement. I am glad that you like it! 😊'
	elsif body.include? 'Joke was bad'
		'Sorry, I am not good at jokes. But I will try harder. 😔'
	elsif body == 'fact'
		file = File.open("facts.txt", "r")
		array_of_facts = IO.readlines("facts.txt")
		return array_of_facts.sample
	else
		"Oops! I didn't get that. Say 'hi', 'who', 'what' or 'why' if you want to know more about me. "
	end
end

#trigger conversation with sentence
def has_vocab_in_sentence words, vocabs
	vocabs.each do |vocab|
		if words.include? vocab
			return true
		end
	end
	return false
end