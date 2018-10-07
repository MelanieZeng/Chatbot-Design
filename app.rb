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
		"Imagine when you are sitting in a nice bar and wondering what drink you should get, your bartender made you a perfect cocktail for the night. Wouldn't it be nice?! Sign up to chat with me now! <br />Total visits on our website: " + session["visits"].to_s
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

#modify incoming/sms page
get '/incoming/sms' do
	session["counter"] ||= 1
	time = Time.now
	media_content = params[:MediaContentType0] || ""
	media_url = params[:MediaUrl0] || ""
	body = params[:Body] || ""

	if not media_url.nil? and not media_url == "" and media_content.include? "image" 

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
		# hair_set = face_attributes["hair"]
		# hair_color_set = hair_set["hairColor"] #It's an array and the elements are dictionary
		# hair_color_confidence_max = hair_color_set.select {|k,v| v == values.max }
		makeup = face_attributes["makeup"]
		lipmakeup = makeup["lipMakeup"]
		emotion_set = face_attributes["emotion"]
		emotion_set_max_value_map = emotion_set.select {|k,v| v == emotion_set.values.max } #It's a dictionary
		emotion_keys = emotion_set_max_value_map.keys #It's an array
		emotion = emotion_keys[0] #Take the first string

		face_recogition_successful = true

	else
		face_recogition_successful = false
	end

	if face_recogition_successful == false
		if session["counter"] == 1
			#greeting based on different time of a day
			if time.hour >= 5 and time.hour <= 12
	    		message = greetings_mn.sample + " Great to hear your first message! I am Moscow Muler🍸. Hope we will have fun time together! "
				media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
			elsif time.hour > 12 and time.hour <= 18
				message = greetings_an.sample + " Great to hear your first message! I am Moscow Muler🍸. Hope we will have fun time together! "
				media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
			else
				message = greetings_en.sample + " Great to hear your first message! I am Moscow Muler🍸. Hope we will have fun time together! "
				media = "https://media0.giphy.com/media/3o7TKMt1VVNkHV2PaE/giphy.gif"
			end
    	else
    		message = determine_response body
    	end
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
				if lipmakeup == true
					message = "A "+ drink["strDrink"] + "would be a perfect match with the lipstick you have on!"
				else
					message = "I love your happy face! Let's partyyy!! Get some " + drink["strDrink"] + "! "
				end
				media = drink["strDrinkThumb"]
			elsif emotion == "neutral"
				uri = URI("https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=Cocktail")
				response = Net::HTTP.get(uri)
				drink_dicionary = JSON.parse(response)
				drink_array = drink_dicionary["drinks"]
				drink = drink_array.sample
				message = "You need a " + drink["strDrink"] + " to get more party energy! Btw, I love your " + " " + " hair."
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
	what_vocabs = ["what do you do" "what do you do?"]
	fact_vocabs = ["fun fact", "fact", "what are some fun facts about you"]

	if has_vocab_in_sentence body, hi_vocabs
		'Hey, I am Moscow Muler 🍸! People call me their "virtual bartender" or "party host". If you want to know more about me, you can ask me questions like "what do you do", "what are some fun facts about you", or play "Never have I ever" with me.'
	elsif has_vocab_in_sentence body, what_vocabs
		'Show me your ready-party look and I will pick you the perfect cocktail based on your mood. I can also recommend a get-her/get-him drink for your girl/man tonight if you send me their photos! 😉'
	elsif has_vocab_in_sentence body, fact_vocabs
		file = File.open("facts.txt", "r")
		array_of_facts = IO.readlines("facts.txt")
		return array_of_facts.sample
	elsif body == 'never have i ever'
		"Here's how we're gonna play. Type 'next' to get a never have I ever statement from me. If you have done the thing I said, reply 'I lost' and take a shot. If not, keep going."
	elsif body == 'next'
		file = File.open("NHIE.txt", "r")
		array_of_facts = IO.readlines("NHIE.txt")
		return array_of_facts.sample
	elsif body == 'i lost'
		"Don't cheat - I am watching you! 😉 If you need help picking a drink, send me a selfie!"
	else
		'Oops! I didnt get that. If you want to know more about me, you can ask me questions like "what do you do", "what are some fun facts about you", or play "Never have I ever" with me.'
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
