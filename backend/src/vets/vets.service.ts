import { BadGatewayException, Injectable, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NearbyQueryDto } from '../common/dto/nearby-query.dto';

const NEARBY_SEARCH_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
const PLACE_DETAILS_URL = 'https://maps.googleapis.com/maps/api/place/details/json';
const EARTH_RADIUS_KM = 6371;

interface GooglePlacesNearbyResult {
  place_id: string;
  name: string;
  vicinity?: string;
  geometry: { location: { lat: number; lng: number } };
  rating?: number;
  user_ratings_total?: number;
  opening_hours?: { open_now?: boolean };
}

interface GooglePlacesNearbyResponse {
  status: string;
  error_message?: string;
  results: GooglePlacesNearbyResult[];
}

interface GooglePlaceDetailsResult {
  place_id: string;
  name: string;
  formatted_address?: string;
  formatted_phone_number?: string;
  international_phone_number?: string;
  geometry: { location: { lat: number; lng: number } };
  opening_hours?: { weekday_text?: string[]; open_now?: boolean };
}

interface GooglePlaceDetailsResponse {
  status: string;
  error_message?: string;
  result?: GooglePlaceDetailsResult;
}

export interface VetPlaceResponse {
  placeId: string;
  name: string;
  address: string | null;
  location: { latitude: number; longitude: number };
  distanceKm: number;
  rating: number | null;
  userRatingsTotal: number | null;
  openNow: boolean | null;
}

export interface VetPlaceDetailResponse {
  placeId: string;
  name: string;
  address: string | null;
  location: { latitude: number; longitude: number };
  phone: string | null;
  openingHours: string[] | null;
  openNow: boolean | null;
}

/**
 * Proxy al Places API de Google (server-side, con la key en
 * GOOGLE_PLACES_API_KEY) para no exponer una key de servidor sin
 * restricciones en el cliente Flutter y para poder pedir Place Details solo
 * bajo demanda (cuidar cuota/costo) en vez de por cada item del listado.
 */
@Injectable()
export class VetsService {
  constructor(private readonly config: ConfigService) {}

  async findNearby({ lat, lng, radiusKm }: NearbyQueryDto): Promise<VetPlaceResponse[]> {
    const url = new URL(NEARBY_SEARCH_URL);
    url.searchParams.set('location', `${lat},${lng}`);
    url.searchParams.set('radius', String(Math.round(radiusKm * 1000)));
    url.searchParams.set('type', 'veterinary_care');
    url.searchParams.set('language', 'es');
    url.searchParams.set('key', this.apiKey());

    const data = await this.fetchJson<GooglePlacesNearbyResponse>(url);
    if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
      throw new BadGatewayException(`Google Places respondió ${data.status}: ${data.error_message ?? ''}`.trim());
    }

    return (data.results ?? [])
      .map((result) => this.toNearbyResponse(result, lat, lng))
      .sort((a, b) => a.distanceKm - b.distanceKm);
  }

  async findDetail(placeId: string): Promise<VetPlaceDetailResponse> {
    const url = new URL(PLACE_DETAILS_URL);
    url.searchParams.set('place_id', placeId);
    url.searchParams.set(
      'fields',
      'place_id,name,formatted_address,formatted_phone_number,international_phone_number,geometry,opening_hours',
    );
    url.searchParams.set('language', 'es');
    url.searchParams.set('key', this.apiKey());

    const data = await this.fetchJson<GooglePlaceDetailsResponse>(url);
    if (data.status === 'NOT_FOUND') {
      throw new NotFoundException('Veterinaria no encontrada.');
    }
    if (data.status !== 'OK' || !data.result) {
      throw new BadGatewayException(`Google Places respondió ${data.status}: ${data.error_message ?? ''}`.trim());
    }

    const result = data.result;
    return {
      placeId: result.place_id,
      name: result.name,
      address: result.formatted_address ?? null,
      location: { latitude: result.geometry.location.lat, longitude: result.geometry.location.lng },
      phone: result.international_phone_number ?? result.formatted_phone_number ?? null,
      openingHours: result.opening_hours?.weekday_text ?? null,
      openNow: result.opening_hours?.open_now ?? null,
    };
  }

  private toNearbyResponse(result: GooglePlacesNearbyResult, originLat: number, originLng: number): VetPlaceResponse {
    const { lat, lng } = result.geometry.location;
    return {
      placeId: result.place_id,
      name: result.name,
      address: result.vicinity ?? null,
      location: { latitude: lat, longitude: lng },
      distanceKm: this.haversineKm(originLat, originLng, lat, lng),
      rating: result.rating ?? null,
      userRatingsTotal: result.user_ratings_total ?? null,
      openNow: result.opening_hours?.open_now ?? null,
    };
  }

  /** Nearby Search no devuelve distancia; se calcula acá (mismo cálculo que GeoLocation.distanceInKmTo en Flutter). */
  private haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const toRad = (deg: number) => (deg * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
    return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  private apiKey(): string {
    const key = this.config.get<string>('GOOGLE_PLACES_API_KEY');
    if (!key) {
      throw new InternalServerErrorException('GOOGLE_PLACES_API_KEY no está configurada en el backend.');
    }
    return key;
  }

  private async fetchJson<T>(url: URL): Promise<T> {
    const response = await fetch(url);
    if (!response.ok) {
      throw new BadGatewayException(`Google Places respondió HTTP ${response.status}.`);
    }
    return (await response.json()) as T;
  }
}
