import 'dart:convert';

enum MaterialCategory {
	activeMaterial,
	conductiveAdditive,
	binder,
}

class MaterialPreset {
	final String id;
	final String name;
	final MaterialCategory category;
	final double trueDensity;
	final double? specificCapacity;
	final String memo;

	const MaterialPreset({
		required this.id,
		required this.name,
		required this.category,
		required this.trueDensity,
		this.specificCapacity,
		this.memo = '',
		bool? isCustom,
	});

	MaterialPreset copyWith({
		String? id,
		String? name,
		MaterialCategory? category,
		double? trueDensity,
		double? specificCapacity,
		bool clearSpecificCapacity = false,
		String? memo,
		bool? isCustom,
	}) {
		return MaterialPreset(
			id: id ?? this.id,
			name: name ?? this.name,
			category: category ?? this.category,
			trueDensity: trueDensity ?? this.trueDensity,
			specificCapacity: clearSpecificCapacity ? null : (specificCapacity ?? this.specificCapacity),
			memo: memo ?? this.memo,
		);
	}

	bool get isCustom => true;

	Map<String, Object?> toMap() {
		return {
			'id': id,
			'name': name,
			'category': category.name,
			'trueDensity': trueDensity,
			'specificCapacity': specificCapacity,
			'memo': memo,
		};
	}

	static MaterialPreset fromMap(Map<String, Object?> map) {
		final rawCategory = (map['category'] as String?) ?? '';
		final normalized = rawCategory.trim().toLowerCase();

		final MaterialCategory category;
		switch (normalized) {
			case 'active_material':
			case 'active material':
			case 'activematerial':
			case 'active':
				category = MaterialCategory.activeMaterial;
				break;
			case 'conductive_additive':
			case 'conductive additive':
			case 'conductiveadditive':
			case 'conductive':
				category = MaterialCategory.conductiveAdditive;
				break;
			case 'binder':
				category = MaterialCategory.binder;
				break;
			default:
				category = MaterialCategory.activeMaterial;
		}

		return MaterialPreset(
			id: (map['id'] as String?) ?? '',
			name: (map['name'] as String?) ?? '',
			category: category,
			trueDensity: (map['trueDensity'] as num?)?.toDouble() ?? 0,
			specificCapacity: (map['specificCapacity'] as num?)?.toDouble(),
			memo: (map['memo'] as String?) ?? '',
		);
	}

	String toJson() => jsonEncode(toMap());

	static MaterialPreset fromJson(String source) {
		final map = jsonDecode(source) as Map<String, dynamic>;
		return fromMap(map);
	}

	@override
	bool operator ==(Object other) {
		if (identical(this, other)) return true;
		return other is MaterialPreset &&
				other.id == id &&
				other.name == name &&
				other.category == category &&
				other.trueDensity == trueDensity &&
				other.specificCapacity == specificCapacity &&
				other.memo == memo;
	}

	@override
	int get hashCode => Object.hash(id, name, category, trueDensity, specificCapacity, memo);
}
