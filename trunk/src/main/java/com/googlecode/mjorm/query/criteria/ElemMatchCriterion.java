package com.googlecode.mjorm.query.criteria;

import com.googlecode.mjorm.mql.MqlFieldFunction;
import com.googlecode.mjorm.mql.MqlFieldFunctionImpl;
import com.googlecode.mjorm.query.Query;
import com.mongodb.BasicDBObject;

public class ElemMatchCriterion
	implements Criterion {

	private Query queryCriterion;

	public ElemMatchCriterion(Query queryCriterion) {
		this.queryCriterion = queryCriterion;
	}

	public ElemMatchCriterion() {
		this.queryCriterion = new Query();
	}

	/**
	 * @return the queryCriterion
	 */
	public Query getQuery() {
		return queryCriterion;
	}

	/**
	 * {@inheritDoc}
	 */
	public Object toQueryObject() {
		return new BasicDBObject("$elemMatch", queryCriterion.toQueryObject());
	}

	public static final MqlFieldFunction MQL_FUNCTION = new MqlFieldFunctionImpl() {
		@Override
		protected Criterion doCreate(Query query) {
			return new ElemMatchCriterion(query);
		}
	};

}