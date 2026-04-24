import 'package:smarttrip_ai/modules/home/models/home_destination.dart';

const List<HomeDestination> kHomeDestinations = <HomeDestination>[
  HomeDestination(
    id: 'tokyo',
    name: 'Tokyo',
    flag: '\u{1F1EF}\u{1F1F5}',
    description:
        'Tokyo is a vibrant metropolis where ancient traditions coexist with futuristic innovation. Visitors can explore historic temples like Senso-ji, walk through the bustling Shibuya Crossing, and experience unique districts such as Akihabara for anime culture and Ginza for luxury shopping. The city offers world-class cuisine ranging from street food to Michelin-star restaurants. With its efficient transport, clean environment, and endless attractions, Tokyo is ideal for both first-time travelers and seasoned explorers.',
    bestTime: 'March - May, October - November',
    budget: 'High',
    rating: 4.8,
    pexelsQuery: 'Tokyo Japan city skyline travel',
  ),
  HomeDestination(
    id: 'london',
    name: 'London',
    flag: '\u{1F1EC}\u{1F1E7}',
    description:
        'London is a city rich in heritage, culture, and modern lifestyle. From iconic landmarks like Big Ben, Tower Bridge, and Buckingham Palace to world-famous museums such as the British Museum, there is always something to explore. Visitors can enjoy theatre shows in the West End, relax in beautiful parks like Hyde Park, and experience diverse cuisines from around the world. London\'s blend of history and modernity makes it a must-visit destination.',
    bestTime: 'March - May',
    budget: 'High',
    rating: 4.7,
    pexelsQuery: 'London England travel landmarks',
  ),
  HomeDestination(
    id: 'paris',
    name: 'Paris',
    flag: '\u{1F1EB}\u{1F1F7}',
    description:
        'Paris is renowned for its romantic charm, artistic heritage, and timeless beauty. The city is home to iconic attractions like the Eiffel Tower, Louvre Museum, and Notre-Dame Cathedral. Visitors can stroll along the Seine River, explore charming neighborhoods, and enjoy authentic French cuisine in cozy cafes. Paris also offers a vibrant shopping scene and rich cultural experiences, making it perfect for both leisure and exploration.',
    bestTime: 'April - June, September - October',
    budget: 'High',
    rating: 4.8,
    pexelsQuery: 'Paris France Eiffel Tower travel',
  ),
  HomeDestination(
    id: 'dubai',
    name: 'Dubai',
    flag: '\u{1F1E6}\u{1F1EA}',
    description:
        'Dubai is a global city known for luxury, innovation, and architectural wonders. It features iconic attractions such as the Burj Khalifa, Palm Jumeirah, and Dubai Mall. Visitors can enjoy desert safaris, water parks, and cultural experiences in traditional souks. Dubai offers a unique mix of modern lifestyle and Arabian heritage, making it suitable for adventure seekers as well as luxury travelers.',
    bestTime: 'November - March',
    budget: 'High',
    rating: 4.6,
    pexelsQuery: 'Dubai UAE travel skyline',
  ),
  HomeDestination(
    id: 'singapore',
    name: 'Singapore',
    flag: '\u{1F1F8}\u{1F1EC}',
    description:
        'Singapore is a modern and well-organized city known for its cleanliness, greenery, and diverse culture. Key attractions include Marina Bay Sands, Gardens by the Bay, and Sentosa Island. The city is also famous for its street food, offering a wide variety of cuisines. Singapore\'s efficient public transport and safe environment make it an excellent destination for short and comfortable trips.',
    bestTime: 'February - April',
    budget: 'Medium',
    rating: 4.7,
    pexelsQuery: 'Singapore city travel Marina Bay',
  ),
  HomeDestination(
    id: 'kerala',
    name: 'Kerala',
    flag: '\u{1F1EE}\u{1F1F3}',
    description:
        'Kerala, often called "God\'s Own Country," is known for its natural beauty and peaceful environment. Visitors can enjoy houseboat cruises through the backwaters, explore lush tea plantations in Munnar, and relax on scenic beaches like Varkala. The region is also famous for Ayurvedic treatments and traditional culture. Kerala is perfect for travelers seeking relaxation, nature, and cultural experiences.',
    bestTime: 'October - March',
    budget: 'Medium',
    rating: 4.6,
    pexelsQuery: 'Kerala India backwaters travel',
  ),
];
