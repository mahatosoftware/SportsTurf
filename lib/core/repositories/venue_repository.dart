import '../../features/venue/models/venue.dart';

abstract class IVenueRepository {
  Future<List<Venue>> getVenues({String? leagueId});
  Future<Venue?> getVenueById(String id);
  Future<void> saveVenue(Venue venue);
  Future<void> deleteVenue(String id);
  Stream<List<Venue>> watchVenues({String? leagueId});
  Stream<Venue?> watchVenue(String id);
}
