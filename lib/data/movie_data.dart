import '../models/movie.dart';

List<Movie> movies = [
Movie(
id: 1,
title: 'El Tesoro Perdido',
imageUrl: 'https://example.com/tesoro_perdido.jpg',
rating: 8.2,
releaseDate: '2023-05-15',
actors: ['Actor A', 'Actor B'],
description: 'Una épica aventura en busca de un tesoro legendario perdido en las profundidades de una jungla misteriosa.',
category: 'Aventura',
),
Movie(
id: 2,
title: 'Luchador Valiente',
imageUrl: 'https://example.com/luchador_valiente.jpg',
rating: 7.8,
releaseDate: '2022-11-20',
actors: ['Actor C', 'Actor D'],
description: 'Un luchador enfrenta sus demonios internos mientras lidera una batalla por el honor y la justicia.',
category: 'Acción',
),
// Agrega las demás películas siguiendo este formato
];